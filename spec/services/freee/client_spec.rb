require "rails_helper"

RSpec.describe Freee::Client do
  let(:config) do
    double("config",
      freee_client_id: "cid", freee_client_secret: "secret",
      freee_static_access_token: nil,
      freee_redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      freee_api_base_url: "https://api.freee.co.jp",
      freee_oauth_base_url: "https://accounts.secure.freee.co.jp",
      freee_company_id: "100", freee_walletable_id: "9",
      freee_walletable_type: "bank_account")
  end
  let(:credential) { FreeeCredential.create!(access_token: "old", refresh_token: "r1", expires_at: 1.hour.from_now) }
  subject(:client) { described_class.new(config: config, credential: credential) }

  def token_body(access:, refresh:, expires_in: 21600)
    JSON.generate(access_token: access, refresh_token: refresh, expires_in: expires_in)
  end

  it "未設定なら access_token! は AuthError" do
    cred = FreeeCredential.new
    c = described_class.new(config: config, credential: cred)
    expect { c.access_token! }.to raise_error(Freee::Client::AuthError)
  end

  it "静的トークンがあればリフレッシュせずそれを返す" do
    allow(config).to receive(:freee_static_access_token).and_return("STATIC")
    c = described_class.new(config: config, credential: FreeeCredential.new)
    expect(c.access_token!).to eq("STATIC")
    expect(c.static_token?).to be(true)
  end

  it "静的トークンで401なら再試行せず AuthError" do
    allow(config).to receive(:freee_static_access_token).and_return("STATIC")
    allow(client).to receive(:request).and_return([401, "unauthorized"])
    expect { client.companies }.to raise_error(Freee::Client::AuthError, /失効|無効/)
  end

  it "失効間近なら自動リフレッシュし、ローテーションした両トークンを保存する" do
    credential.update!(expires_at: 1.minute.from_now) # バッファ内＝失効扱い
    allow(client).to receive(:request)
      .and_return([200, token_body(access: "new-at", refresh: "new-rt")])

    expect(client.access_token!).to eq("new-at")
    expect(credential.reload.refresh_token).to eq("new-rt")
    expect(credential.expired?).to be(false)
  end

  it "exchange_code! はトークンを保存する" do
    cred = FreeeCredential.new
    c = described_class.new(config: config, credential: cred)
    allow(c).to receive(:request)
      .and_return([200, token_body(access: "AT", refresh: "RT")])

    c.exchange_code!("authcode")
    expect(cred.reload.access_token).to eq("AT")
    expect(cred.refresh_token).to eq("RT")
  end

  it "API GETが401なら1度だけリフレッシュして再試行する" do
    call = 0
    allow(client).to receive(:request) do |method, uri, **_|
      if uri.to_s.include?("/public_api/token")
        [200, token_body(access: "refreshed", refresh: "r2")]
      else
        call += 1
        (call == 1) ? [401, "unauthorized"] : [200, JSON.generate(companies: [{id: 1}])]
      end
    end

    expect(client.companies).to eq([{"id" => 1}])
  end

  it "wallet_txns は期間指定で配列を返す" do
    allow(client).to receive(:request)
      .and_return([200, JSON.generate(wallet_txns: [{id: 1, entry_side: "income", amount: 100}])])

    txns = client.wallet_txns(start_date: "2026-05-15", end_date: "2026-05-18")
    expect(txns.first["entry_side"]).to eq("income")
  end
end
