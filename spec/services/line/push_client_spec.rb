require "rails_helper"

RSpec.describe Line::PushClient do
  let(:messages) { [{type: "text", text: "hi"}] }

  def client(mode:, token: "tok", user_id: nil)
    config = double(
      "config",
      line_delivery_mode: mode,
      line_channel_access_token: token,
      line_target_user_id: user_id,
      line_push_endpoint: "https://api.line.me/v2/bot/message/push",
      line_broadcast_endpoint: "https://api.line.me/v2/bot/message/broadcast"
    )
    described_class.new(config: config)
  end

  it "broadcastモードは broadcast エンドポイントへ to なしで送る" do
    c = client(mode: "broadcast")
    expect(c).to receive(:post)
      .with("https://api.line.me/v2/bot/message/broadcast", {messages: messages})
    c.deliver(messages)
  end

  it "pushモードは push エンドポイントへ to つきで送る" do
    c = client(mode: "push", user_id: "U123")
    expect(c).to receive(:post)
      .with("https://api.line.me/v2/bot/message/push", {to: "U123", messages: messages})
    c.deliver(messages)
  end

  it "pushモードで宛先未設定なら PushError" do
    c = client(mode: "push", user_id: nil)
    expect { c.deliver(messages) }
      .to raise_error(Line::PushClient::PushError, /LINE_NOTIFY_USER_ID/)
  end
end
