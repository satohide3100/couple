module LiffAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_liff_user!
  end

  private

  def authenticate_liff_user!
    unless liff_user_id.present?
      redirect_to new_session_path
    end
  end

  def liff_user_id
    session[:liff_user_id]
  end

  def current_user_id
    liff_user_id
  end
end