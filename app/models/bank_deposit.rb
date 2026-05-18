class BankDeposit < ApplicationRecord
  validates :message_id, presence: true, uniqueness: true
  validates :amount, presence: true
  validates :raw_payload, presence: true

  scope :unnotified, -> { where(notified_at: nil) }

  # 受信済みのメッセージIDか（冪等性チェック）
  def self.already_received?(message_id)
    exists?(message_id: message_id)
  end

  # 入金 payload（Freee::DepositTxn 等のダックタイプ）から永続化レコードを作成する。
  # 既に同じ message_id を保存済みなら nil を返す（重複は無視＝冪等）。
  def self.record_from_payload(payload)
    create!(
      message_id: payload.message_id,
      source: payload.try(:source) || "freee",
      amount: payload.amount,
      remitter_name: payload.remitter_name,
      value_date: payload.value_date,
      transaction_date: payload.transaction_date,
      va_account_number: payload.va_account_number,
      va_account_name: payload.va_account_name,
      payment_bank_name: payload.payment_bank_name,
      remarks: payload.remarks,
      event_timestamp: payload.event_timestamp,
      raw_payload: payload.raw_json
    )
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def notified?
    notified_at.present?
  end

  def mark_notified!
    update!(notified_at: Time.current)
  end

  def amount_yen
    Integer(amount, exception: false) || amount
  end
end
