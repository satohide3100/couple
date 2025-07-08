class ApplicationController < ActionController::Base
  # CSRF対策（LIFFトークン検証で代替）
  protect_from_forgery with: :exception, unless: -> { request.xhr? }

  before_action :set_csrf_token_header

  # アップロードされたファイルの配信（本番環境用）
  def serve_file
    if Rails.env.production?
      file_path = Rails.root.join('tmp', 'uploads', params[:path])
      if File.exist?(file_path)
        send_file file_path, disposition: 'inline'
      else
        render plain: 'File not found', status: 404
      end
    else
      render plain: 'Not found', status: 404
    end
  end

  private

  def set_csrf_token_header
    response.headers['X-CSRF-Token'] = form_authenticity_token if request.xhr?
  end
end
