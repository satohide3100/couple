require "rails_helper"

RSpec.describe Freee::DepositTxn do
  let(:income) do
    described_class.new(
      {"id" => 555, "date" => "2026-05-18", "amount" => 30000,
       "entry_side" => "income", "walletable_id" => 9, "description" => "ﾌﾘｺﾐ"},
      walletable_name: "あおぞら 普通"
    )
  end

  it "income? を判定し、message_idは衝突回避の接頭辞付き" do
    expect(income).to be_income
    expect(income.message_id).to eq("freee-555")
    expect(income.source).to eq("freee")
  end

  it "通知ドメインのダックタイプを満たす" do
    expect(income.amount).to eq("30000")
    expect(income.value_date).to eq("2026-05-18")
    expect(income.remitter_name).to be_nil
    expect(income.payment_bank_name).to eq("あおぞら 普通")
    expect(income.remarks).to eq("ﾌﾘｺﾐ")
    expect(JSON.parse(income.raw_json)["id"]).to eq(555)
  end

  it "expense は income? が false" do
    expense = described_class.new({"id" => 1, "entry_side" => "expense", "amount" => -100})
    expect(expense).not_to be_income
  end
end
