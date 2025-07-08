class SessionsController < ApplicationController
  def new
    # LIFF ログイン画面を表示
  end

  def create
    # LIFF からのユーザー情報を検証
    liff_user_id = params[:liff_user_id]
    
    if liff_user_id.present?
      session[:liff_user_id] = liff_user_id
      redirect_to dashboard_path
    else
      redirect_to new_session_path, alert: "ログインに失敗しました"
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path
  end
end