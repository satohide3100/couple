# freee会計 入金検知 / LINE 通知の設定値を ENV から読む。
#
# 値は dotenv(.env) または Railway の環境変数から供給される。
module BankNotificationConfig
  module_function

  # ---- freee会計 API ----

  def freee_client_id
    presence(ENV["FREEE_CLIENT_ID"])
  end

  def freee_client_secret
    presence(ENV["FREEE_CLIENT_SECRET"])
  end

  def freee_redirect_uri
    ENV.fetch("FREEE_REDIRECT_URI", "urn:ietf:wg:oauth:2.0:oob")
  end

  # 静的アクセストークン（動作確認用）。設定時はリフレッシュせずこれを使う。
  # freeeのテスト用トークンは約6時間で失効するため恒久運用には不向き。
  def freee_static_access_token
    presence(ENV["FREEE_ACCESS_TOKEN"])
  end

  def freee_api_base_url
    ENV.fetch("FREEE_API_BASE_URL", "https://api.freee.co.jp")
  end

  def freee_oauth_base_url
    ENV.fetch("FREEE_OAUTH_BASE_URL", "https://accounts.secure.freee.co.jp")
  end

  # 監視対象（事業所・口座）
  def freee_company_id
    presence(ENV["FREEE_COMPANY_ID"])
  end

  def freee_walletable_id
    presence(ENV["FREEE_WALLETABLE_ID"])
  end

  def freee_walletable_type
    ENV.fetch("FREEE_WALLETABLE_TYPE", "bank_account")
  end

  # ポーリングで遡る日数（freeeの銀行同期遅延に対するマージン）
  def freee_lookback_days
    Integer(ENV.fetch("FREEE_LOOKBACK_DAYS", "3"), exception: false) || 3
  end

  # 認証手段があるか（静的トークン or OAuthクライアント）
  def freee_auth_configured?
    freee_static_access_token.present? ||
      (freee_client_id.present? && freee_client_secret.present?)
  end

  # ポーリング実行に必要な設定が揃っているか
  def freee_ready?
    freee_auth_configured? &&
      freee_company_id.present? && freee_walletable_id.present?
  end

  # ---- LINE Messaging API（送信）----

  # Messaging APIチャネルの長期チャネルアクセストークン
  def line_channel_access_token
    ENV["LINE_CHANNEL_ACCESS_TOKEN"]
  end

  # 配信方式: "broadcast"(友だち全員へ一斉) または "push"(特定userId)。既定 broadcast。
  def line_delivery_mode
    mode = ENV.fetch("LINE_DELIVERY_MODE", "broadcast").to_s.strip.downcase
    %w[broadcast push].include?(mode) ? mode : "broadcast"
  end

  def broadcast?
    line_delivery_mode == "broadcast"
  end

  # push方式のときの通知先 LINE userId
  def line_target_user_id
    ENV["LINE_NOTIFY_USER_ID"]
  end

  def line_push_endpoint
    "https://api.line.me/v2/bot/message/push"
  end

  def line_broadcast_endpoint
    "https://api.line.me/v2/bot/message/broadcast"
  end

  # 必須設定が揃っているか（起動時/タスク実行時の早期チェック用）
  # broadcast: チャネルアクセストークンのみ / push: + 宛先userId
  def line_ready?
    return false if line_channel_access_token.blank?

    broadcast? || line_target_user_id.present?
  end

  def presence(value)
    value.to_s.strip.empty? ? nil : value
  end
end
