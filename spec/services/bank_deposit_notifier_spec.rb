require "rails_helper"

RSpec.describe BankDepositNotifier do
  let(:push_client) { instance_double(Line::PushClient) }
  subject(:notifier) { described_class.new(push_client: push_client) }

  def txn(id: 12345, amount: 10000)
    Freee::DepositTxn.new(
      {
        "id" => id, "date" => "2026-05-18", "amount" => amount,
        "entry_side" => "income", "walletable_id" => 99,
        "description" => "振込 テスト"
      },
      walletable_name: "GMOあおぞら 普通"
    )
  end

  it "新規入金を保存しLINE送信して notified を返す" do
    expect(push_client).to receive(:deliver).once

    result = notifier.call(txn)

    expect(result.status).to eq(:notified)
    deposit = BankDeposit.find_by(message_id: "freee-12345")
    expect(deposit).to be_present
    expect(deposit.source).to eq("freee")
    expect(deposit).to be_notified
  end

  it "同じ取引の重複検知は二重送信しない" do
    allow(push_client).to receive(:deliver)
    notifier.call(txn)

    expect(push_client).not_to receive(:deliver)
    result = notifier.call(txn)

    expect(result.status).to eq(:duplicate)
    expect(BankDeposit.where(message_id: "freee-12345").count).to eq(1)
  end

  it "LINE送信失敗時もレコードは保存し saved_not_notified を返す" do
    allow(push_client).to receive(:deliver)
      .and_raise(Line::PushClient::PushError, "boom")

    result = notifier.call(txn)

    expect(result.status).to eq(:saved_not_notified)
    expect(BankDeposit.find_by(message_id: "freee-12345")).not_to be_notified
  end
end
