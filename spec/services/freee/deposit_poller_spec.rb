require "rails_helper"

RSpec.describe Freee::DepositPoller do
  let(:client) { instance_double(Freee::Client) }
  let(:push_client) { instance_double(Line::PushClient) }
  let(:notifier) { BankDepositNotifier.new(push_client: push_client) }
  let(:config) do
    double("config", freee_ready?: true, freee_lookback_days: 3,
      freee_walletable_id: "9")
  end
  subject(:poller) { described_class.new(client: client, notifier: notifier, config: config) }

  before do
    allow(client).to receive(:walletables)
      .and_return([{"id" => 9, "name" => "あおぞら 普通", "type" => "bank_account"}])
    allow(push_client).to receive(:deliver)
  end

  it "入金のみ通知し、支出は無視する" do
    allow(client).to receive(:wallet_txns).and_return([
      {"id" => 1, "date" => "2026-05-18", "amount" => 5000, "entry_side" => "income", "walletable_id" => 9, "description" => "A"},
      {"id" => 2, "date" => "2026-05-18", "amount" => -800, "entry_side" => "expense", "walletable_id" => 9, "description" => "B"}
    ])

    summary = poller.call(today: Date.new(2026, 5, 18))

    expect(summary.fetched).to eq(2)
    expect(summary.income).to eq(1)
    expect(summary.notified).to eq(1)
    expect(BankDeposit.pluck(:message_id)).to eq(["freee-1"])
    expect(push_client).to have_received(:deliver).once
  end

  it "再ポーリングしても既知の入金は重複扱いで再送しない" do
    allow(client).to receive(:wallet_txns).and_return([
      {"id" => 1, "date" => "2026-05-18", "amount" => 5000, "entry_side" => "income", "walletable_id" => 9}
    ])

    poller.call(today: Date.new(2026, 5, 18))
    summary = poller.call(today: Date.new(2026, 5, 18))

    expect(summary.duplicate).to eq(1)
    expect(summary.notified).to eq(0)
    expect(push_client).to have_received(:deliver).once
  end

  it "freee設定不足なら ArgumentError" do
    allow(config).to receive(:freee_ready?).and_return(false)
    expect { poller.call }.to raise_error(ArgumentError)
  end

  it "対象口座へ date 範囲付きで問い合わせる" do
    expect(client).to receive(:wallet_txns)
      .with(start_date: "2026-05-15", end_date: "2026-05-18")
      .and_return([])

    poller.call(today: Date.new(2026, 5, 18))
  end
end
