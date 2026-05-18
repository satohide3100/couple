require "net/http"
require "json"
require "uri"

module Freee
  # freee会計 API クライアント（外部gemなし・Net::HTTP）。
  #
  # OAuth2 認可コードフロー:
  #   1. authorize_url をブラウザで開いて認可 → 認可コード取得
  #   2. exchange_code!(code) でトークン取得・保存
  #   3. 以降は access_token! が失効間近で自動リフレッシュ
  #      （freeeは refresh_token もローテーションするため毎回保存）
  #
  # データ取得: companies / walletables / wallet_txns
  class Client
    class ApiError < StandardError; end

    class AuthError < ApiError; end

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 20

    def initialize(config: BankNotificationConfig, credential: FreeeCredential.instance)
      @config = config
      @credential = credential
    end

    # ---- OAuth ----

    def authorize_url
      params = {
        client_id: @config.freee_client_id,
        redirect_uri: @config.freee_redirect_uri,
        response_type: "code"
      }
      "#{oauth_base}/public_api/authorize?#{URI.encode_www_form(params)}"
    end

    # 認可コード → トークン（初回のみ）
    def exchange_code!(code)
      data = token_request(
        grant_type: "authorization_code",
        code: code,
        redirect_uri: @config.freee_redirect_uri
      )
      persist_tokens(data)
    end

    # リフレッシュ（自動・手動どちらからも）
    def refresh!
      raise AuthError, "no refresh_token stored; run freee:exchange first" if @credential.refresh_token.blank?

      data = token_request(
        grant_type: "refresh_token",
        refresh_token: @credential.refresh_token
      )
      persist_tokens(data)
    end

    # 有効なアクセストークンを返す。
    # 静的トークン(FREEE_ACCESS_TOKEN)が設定されていればそれを使う（リフレッシュ不可）。
    # 無ければDB保存のトークンを使い、失効間近なら自動リフレッシュ。
    def access_token!
      static = @config.freee_static_access_token
      return static if static.present?

      raise AuthError, "freee credential not configured; run freee:exchange" unless @credential.configured?

      refresh! if @credential.expired?
      @credential.access_token
    end

    def static_token?
      @config.freee_static_access_token.present?
    end

    # ---- API ----

    def companies
      get("/api/1/companies").fetch("companies", [])
    end

    def walletables(company_id: default_company_id)
      params = {company_id: company_id, with_balance: "false"}
      get("/api/1/walletables", params).fetch("walletables", [])
    end

    # 指定口座の入出金明細を取得（期間指定）
    def wallet_txns(start_date:, end_date:, company_id: default_company_id, walletable_id: @config.freee_walletable_id,
      walletable_type: @config.freee_walletable_type, limit: 100)
      params = {
        company_id: company_id,
        walletable_type: walletable_type,
        walletable_id: walletable_id,
        start_date: start_date,
        end_date: end_date,
        limit: limit
      }
      get("/api/1/wallet_txns", params).fetch("wallet_txns", [])
    end

    private

    def default_company_id
      @config.freee_company_id
    end

    def oauth_base
      @config.freee_oauth_base_url.chomp("/")
    end

    def api_base
      @config.freee_api_base_url.chomp("/")
    end

    # GET（401時に1度だけリフレッシュして再試行）
    def get(path, params = {})
      uri = URI.parse("#{api_base}#{path}")
      uri.query = URI.encode_www_form(params.compact) unless params.empty?

      attempt = 0
      begin
        attempt += 1
        status, body = request(:get, uri, bearer: access_token!)
        return parse_json(body) if status.between?(200, 299)

        if status == 401 && attempt == 1 && !static_token?
          refresh!
          raise RetrySignal
        end
        if status == 401 && static_token?
          raise AuthError, "freee API #{path}: 401（静的トークンが失効/無効。FREEE_ACCESS_TOKEN を更新するかOAuthへ移行）"
        end
        raise ApiError, "freee API #{path} failed: #{status} #{body}"
      rescue RetrySignal
        retry
      end
    end

    RetrySignal = Class.new(StandardError)
    private_constant :RetrySignal

    def token_request(form)
      url = URI.parse("#{oauth_base}/public_api/token")
      body = URI.encode_www_form(form.merge(
        client_id: @config.freee_client_id,
        client_secret: @config.freee_client_secret
      ))
      status, raw = request(:post, url, form_body: body)
      raise AuthError, "freee token endpoint failed: #{status} #{raw}" unless status.between?(200, 299)

      parse_json(raw)
    end

    def persist_tokens(data)
      @credential.store_tokens!(
        access_token: data.fetch("access_token"),
        refresh_token: data.fetch("refresh_token"),
        expires_in: data["expires_in"] || 21600
      )
      @credential
    end

    # 低レベルHTTP。テストではこのメソッドをスタブする。
    # 戻り値: [Integer status, String body]
    def request(method, uri, bearer: nil, form_body: nil)
      req =
        case method
        when :get then Net::HTTP::Get.new(uri)
        when :post then Net::HTTP::Post.new(uri)
        else raise ArgumentError, "unsupported method #{method}"
        end

      req["Accept"] = "application/json"
      req["Authorization"] = "Bearer #{bearer}" if bearer
      if form_body
        req["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = form_body
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      res = http.request(req)
      [res.code.to_i, res.body.to_s]
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError => e
      raise ApiError, "freee transport error: #{e.class}: #{e.message}"
    end

    def parse_json(body)
      body.empty? ? {} : JSON.parse(body)
    rescue JSON::ParserError => e
      raise ApiError, "freee invalid JSON: #{e.message}"
    end
  end
end
