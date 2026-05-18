require "rails_helper"

RSpec.describe DepositMessage do
  def txn(overrides = {})
    Freee::DepositTxn.new(
      {"id" => 1, "date" => "2026-05-18", "amount" => 10000,
       "entry_side" => "income", "walletable_id" => 9,
       "description" => "振込 テスト"}.merge(overrides),
      walletable_name: "GMOあおぞら 普通"
    )
  end

  # Flex bubble 内の全 text 要素を再帰的に集める
  def texts(node, acc = [])
    case node
    when Hash
      acc << node[:text] if node[:type] == "text"
      node.each_value { |v| texts(v, acc) }
    when Array
      node.each { |v| texts(v, acc) }
    end
    acc
  end

  it "Flex Message を1枚返す" do
    msg = described_class.new(txn).to_line_messages.first
    expect(msg[:type]).to eq("flex")
    expect(msg[:contents][:type]).to eq("bubble")
  end

  it "altText は通知向けの簡潔テキスト" do
    expect(described_class.new(txn("amount" => 1234567)).alt_text)
      .to eq("💰 入金 ¥1,234,567")
  end

  it "金額・入金日・摘要が bubble に含まれる" do
    all = texts(described_class.new(txn("amount" => 1234567)).to_line_messages.first[:contents])
    expect(all).to include("¥1,234,567")
    expect(all).to include("2026-05-18")
    expect(all).to include("振込 テスト")
    expect(all).to include("入金を検知")
  end

  it "口座(payment_bank_name)はカードに出さない" do
    all = texts(described_class.new(txn).to_line_messages.first[:contents])
    expect(all).not_to include("GMOあおぞら 普通")
    expect(all.none? { |t| t.include?("口座") }).to be(true)
  end

  it "振込人(remitter)が無いfreeeでは振込人行を出さない" do
    all = texts(described_class.new(txn).to_line_messages.first[:contents])
    expect(all.none? { |t| t.include?("振込人") }).to be(true)
  end

  it "振込人があれば altText に付帯する" do
    d = txn.tap { |t| def t.remitter_name = "ﾔﾏﾀﾞ ﾀﾛｳ" }
    expect(described_class.new(d).alt_text).to eq("💰 入金 ¥10,000（ﾔﾏﾀﾞ ﾀﾛｳ）")
  end
end
