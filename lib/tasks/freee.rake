namespace :freee do
  desc "OAuth認可URLを表示（ブラウザで開いて認可コードを取得）"
  task authorize_url: :environment do
    puts Freee::Client.new.authorize_url
  end

  desc "認可コードをトークンに交換して保存: rake 'freee:exchange[CODE]'"
  task :exchange, [:code] => :environment do |_t, args|
    code = args[:code].presence || abort("認可コードを渡してください: rake 'freee:exchange[CODE]'")
    cred = Freee::Client.new.exchange_code!(code)
    puts "[freee] トークン保存完了 (expires_at=#{cred.expires_at})"
    puts "[freee] 次に freee:list_companies / freee:list_walletables で対象IDを確認してください"
  rescue Freee::Client::ApiError => e
    abort "[freee] 交換失敗: #{e.message}"
  end

  desc "事業所一覧（FREEE_COMPANY_ID 用）"
  task list_companies: :environment do
    Freee::Client.new.companies.each do |c|
      puts "  id=#{c["id"]}  #{c["display_name"] || c["name"]}"
    end
  rescue Freee::Client::ApiError => e
    abort "[freee] 取得失敗: #{e.message}"
  end

  desc "口座一覧（FREEE_WALLETABLE_ID / TYPE 用）"
  task list_walletables: :environment do
    Freee::Client.new.walletables.each do |w|
      puts "  id=#{w["id"]}  type=#{w["type"]}  #{w["name"]}"
    end
  rescue Freee::Client::ApiError => e
    abort "[freee] 取得失敗: #{e.message}"
  end

  desc "ドライラン: 送信も保存もせず、直近の入金と新規判定だけ表示"
  task preview: :environment do
    rows = Freee::DepositPoller.new.preview
    if rows.empty?
      puts "[freee] 対象期間に入金(income)はありません"
    else
      rows.each do |r|
        d = r[:deposit]
        mark = r[:new] ? "NEW " : "既知 "
        puts "  #{mark} #{d.value_date} ¥#{d.amount} #{d.message_id} #{d.remarks}"
      end
      puts "[freee] NEW = poll_deposits 実行時にLINE一斉配信される件"
    end
  rescue ArgumentError, Freee::Client::ApiError => e
    abort "[freee] preview失敗: #{e.message}"
  end

  desc "入金をポーリングして新規分をLINE一斉配信（Railway Cronから実行）"
  task poll_deposits: :environment do
    summary = Freee::DepositPoller.new.call
    puts "[freee] poll done: #{summary.to_h}"
  rescue ArgumentError, Freee::Client::ApiError => e
    abort "[freee] poll失敗: #{e.message}"
  end

  desc "設定の自己チェック"
  task check_config: :environment do
    c = BankNotificationConfig
    cred = FreeeCredential.instance
    rows = {
      "FREEE_CLIENT_ID/SECRET" => c.freee_client_id.present? && c.freee_client_secret.present?,
      "FREEE_COMPANY_ID" => c.freee_company_id,
      "FREEE_WALLETABLE_ID" => c.freee_walletable_id,
      "FREEE_WALLETABLE_TYPE" => c.freee_walletable_type,
      "FREEE_LOOKBACK_DAYS" => c.freee_lookback_days,
      "freee token保存済み" => cred.configured?,
      "freee token失効" => (cred.configured? ? cred.expired? : "(未取得)"),
      "freeeポーリング準備OK" => c.freee_ready?,
      "LINE_DELIVERY_MODE" => c.line_delivery_mode,
      "LINE送信準備OK" => c.line_ready?
    }
    rows.each { |k, v| puts format("  %-26s : %s", k, v) }
    abort "[freee] 設定不足" unless c.freee_ready? && c.line_ready?
    puts "[freee] 設定OK"
  end
end
