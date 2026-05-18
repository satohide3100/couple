# freee OAuth トークンの保存（単一行のシングルトン）。
#
# freeeのアクセストークンは約6時間で失効し、リフレッシュ時に
# refresh_token も毎回ローテーション（旧トークンは無効化）されるため、
# リフレッシュのたびに必ず新しい両トークンを保存する必要がある。
class FreeeCredential < ApplicationRecord
  # 有効期限のこれだけ手前なら「失効間近」とみなして事前リフレッシュ
  EXPIRY_BUFFER = 5.minutes

  # アプリ全体で1行だけ使う
  def self.instance
    first || new
  end

  def configured?
    access_token.present? && refresh_token.present?
  end

  def expired?
    return true if expires_at.blank?

    Time.current >= (expires_at - EXPIRY_BUFFER)
  end

  # トークン交換/リフレッシュのレスポンスを保存する。
  # expires_in（秒）から expires_at を算出。
  def store_tokens!(access_token:, refresh_token:, expires_in:, company_id: nil)
    update!(
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: Time.current + expires_in.to_i.seconds,
      company_id: company_id.presence || self.company_id
    )
  end
end
