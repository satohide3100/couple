module Freee
  # 対象口座の入出金明細を直近N日分ポーリングし、
  # 入金(entry_side=income)を冪等に検知して LINE 一斉配信する。
  #
  # freeeの銀行自動同期は遅延・後追いがあるため、毎回 lookback_days 分の
  # ウィンドウを取得し直し、BankDeposit の message_id で重複を排除する
  # （新規分だけ通知される）。
  class DepositPoller
    Summary = Struct.new(:fetched, :income, :notified, :duplicate, :failed, keyword_init: true)

    def initialize(client: Freee::Client.new, notifier: BankDepositNotifier.new,
      config: BankNotificationConfig, logger: Rails.logger)
      @client = client
      @notifier = notifier
      @config = config
      @logger = logger
    end

    def call(today: Date.current)
      raise ArgumentError, "freee設定が不足しています (FREEE_* と口座ID)" unless @config.freee_ready?

      end_date = today
      start_date = today - @config.freee_lookback_days

      txns = @client.wallet_txns(
        start_date: start_date.to_s,
        end_date: end_date.to_s
      )
      income = txns.map { |t| DepositTxn.new(t, walletable_name: walletable_name) }
        .select(&:income?)

      summary = Summary.new(fetched: txns.size, income: income.size,
        notified: 0, duplicate: 0, failed: 0)

      income.each do |deposit_txn|
        result = @notifier.call(deposit_txn)
        case result.status
        when :notified then summary.notified += 1
        when :duplicate then summary.duplicate += 1
        else summary.failed += 1
        end
      end

      log_summary(start_date, end_date, summary)
      summary
    end

    # 送信も保存もせず、ウィンドウ内の入金と「新規(未通知)か」を返す。
    def preview(today: Date.current)
      raise ArgumentError, "freee設定が不足しています (FREEE_* と口座ID)" unless @config.freee_ready?

      start_date = today - @config.freee_lookback_days
      txns = @client.wallet_txns(start_date: start_date.to_s, end_date: today.to_s)
      txns.map { |t| DepositTxn.new(t, walletable_name: walletable_name) }
        .select(&:income?)
        .map { |d| {deposit: d, new: !BankDeposit.already_received?(d.message_id)} }
    end

    private

    def log_summary(start_date, end_date, summary)
      @logger.info(
        "[Freee::DepositPoller] window=#{start_date}..#{end_date} " \
        "fetched=#{summary.fetched} income=#{summary.income} " \
        "notified=#{summary.notified} duplicate=#{summary.duplicate} failed=#{summary.failed}"
      )
    end

    # 通知メッセージに出す口座名（対象 walletable の名前）。1回だけ解決。
    def walletable_name
      return @walletable_name if defined?(@walletable_name)

      target = @config.freee_walletable_id.to_s
      match = @client.walletables.find { |w| w["id"].to_s == target }
      @walletable_name = match && match["name"]
    rescue Freee::Client::ApiError => e
      @logger.warn("[Freee::DepositPoller] walletable名の取得に失敗: #{e.message}")
      @walletable_name = nil
    end
  end
end
