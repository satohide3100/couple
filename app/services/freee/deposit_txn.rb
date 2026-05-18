module Freee
  # freee の wallet_txn 1件を、通知ドメイン共通のダックタイプに変換する。
  # （BankDeposit.record_from_payload / DepositMessage が使う口）
  #
  # wallet_txn の主なフィールド:
  #   id, company_id, date(YYYY-MM-DD), amount, due_amount, balance,
  #   entry_side("income"|"expense"), walletable_type, walletable_id, description
  class DepositTxn
    def initialize(txn, walletable_name: nil)
      @txn = txn
      @walletable_name = walletable_name
    end

    def income?
      @txn["entry_side"].to_s == "income"
    end

    # 他ソースと衝突しないよう接頭辞付きで一意化（冪等キー）
    def message_id
      "freee-#{@txn["id"]}"
    end

    def source = "freee"

    def amount
      @txn["amount"].to_s
    end

    # freeeの wallet_txns に振込依頼人名は無い（description に銀行の摘要が入る）
    def remitter_name = nil

    def value_date = @txn["date"]

    def transaction_date = @txn["date"]

    def va_account_number = @txn["walletable_id"].to_s

    def va_account_name = @walletable_name

    def payment_bank_name = @walletable_name

    def remarks = @txn["description"]

    def event_timestamp
      return nil if @txn["date"].blank?

      Time.zone.parse(@txn["date"])
    rescue ArgumentError
      nil
    end

    def raw_json
      JSON.generate(@txn)
    end
  end
end
