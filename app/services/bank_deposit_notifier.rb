# 入金1件(ダックタイプの payload)を受け取り
# 「冪等な保存 → LINE通知 → 通知済みフラグ更新」を行う。
# freeeポーリングと未通知再送タスクから使う。
class BankDepositNotifier
  Result = Struct.new(:status, :bank_deposit, :error, keyword_init: true) do
    # status: :notified（保存+通知成功） / :duplicate（受信済み）
    #         / :saved_not_notified（保存したがLINE送信失敗）
    def ok? = status == :notified || status == :duplicate
  end

  def initialize(push_client: Line::PushClient.new, logger: Rails.logger)
    @push_client = push_client
    @logger = logger
  end

  # payload: Freee::DepositTxn 等（message_id/amount/... を返すダックタイプ）
  def call(payload)
    if BankDeposit.already_received?(payload.message_id)
      @logger.info("[BankDepositNotifier] duplicate messageId=#{payload.message_id} ignored")
      return Result.new(status: :duplicate, bank_deposit: BankDeposit.find_by(message_id: payload.message_id))
    end

    deposit = BankDeposit.record_from_payload(payload)
    # record_from_payload は競合時 nil（別リクエストが先に保存）→ 重複扱い
    return Result.new(status: :duplicate, bank_deposit: BankDeposit.find_by(message_id: payload.message_id)) if deposit.nil?

    deliver(deposit, payload)
  end

  # 保存済みレコードに対して（再送タスクから）LINE通知だけ行う
  def deliver(deposit, payload)
    messages = DepositMessage.new(payload).to_line_messages
    @push_client.deliver(messages)
    deposit.mark_notified!
    @logger.info("[BankDepositNotifier] notified messageId=#{deposit.message_id} amount=#{deposit.amount}")
    Result.new(status: :notified, bank_deposit: deposit)
  rescue Line::PushClient::PushError => e
    # LINE送信失敗。レコードは保存済みなので再送タスクでリカバリ可能。
    # 例外は外に投げず status で表現する。
    @logger.error("[BankDepositNotifier] LINE push failed messageId=#{deposit.message_id}: #{e.message}")
    Result.new(status: :saved_not_notified, bank_deposit: deposit, error: e)
  end
end
