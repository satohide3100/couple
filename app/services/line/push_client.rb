require "net/http"
require "json"
require "uri"

module Line
  # LINE Messaging API クライアント（外部gemを足さず Net::HTTP で実装）。
  #
  # 配信方式は BankNotificationConfig.line_delivery_mode で切替:
  #   - "broadcast": 公式アカウントを友だち追加した全員へ一斉配信
  #       POST https://api.line.me/v2/bot/message/broadcast  { "messages": [...] }
  #   - "push":      特定 userId へプッシュ
  #       POST https://api.line.me/v2/bot/message/push       { "to": "...", "messages": [...] }
  #
  # いずれも Authorization: Bearer {channel access token}
  class PushClient
    class PushError < StandardError; end

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10

    def initialize(config: BankNotificationConfig)
      @config = config
    end

    # 設定された配信方式で送信する（BankDepositNotifier から呼ばれる入口）
    def deliver(messages)
      case @config.line_delivery_mode
      when "push"
        push(messages)
      else
        broadcast(messages)
      end
    end

    # 友だち全員へ一斉配信
    def broadcast(messages)
      post(@config.line_broadcast_endpoint, messages: messages)
    end

    # 特定ユーザーへプッシュ
    def push(messages, to: nil)
      to ||= @config.line_target_user_id
      raise PushError, "LINE_NOTIFY_USER_ID is not configured" if to.blank?

      post(@config.line_push_endpoint, to: to, messages: messages)
    end

    private

    def post(endpoint, body)
      token = @config.line_channel_access_token
      raise PushError, "LINE_CHANNEL_ACCESS_TOKEN is not configured" if token.blank?

      uri = URI.parse(endpoint)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body)

      response = http(uri).request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise PushError, "LINE send failed: #{response.code} #{response.body}"
      end

      response
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError => e
      raise PushError, "LINE send transport error: #{e.class}: #{e.message}"
    end

    def http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http
    end
  end
end
