class ApplicationController < ActionController::Base
  # CSRF対策（LIFFトークン検証で代替）
  protect_from_forgery with: :exception, unless: -> { request.xhr? }

  before_action :set_csrf_token_header

  # アップロードされたファイルの配信（本番環境用）
  def serve_file
    if Rails.env.production?
      file_path = Rails.root.join('tmp', 'uploads', params[:path])
      
      # デバッグログを追加
      Rails.logger.info "=== File Serve Debug ==="
      Rails.logger.info "Requested path: #{params[:path]}"
      Rails.logger.info "Full file path: #{file_path}"
      Rails.logger.info "File exists: #{File.exist?(file_path)}"
      
      # ディレクトリの内容も確認
      dir_path = file_path.dirname
      if Dir.exist?(dir_path)
        Rails.logger.info "Directory contents: #{Dir.entries(dir_path)}"
      else
        Rails.logger.info "Directory does not exist: #{dir_path}"
      end
      
      if File.exist?(file_path)
        Rails.logger.info "Serving file: #{file_path}"
        send_file file_path, disposition: 'inline'
      else
        Rails.logger.info "File not found: #{file_path}"
        render plain: "File not found: #{file_path}", status: 404
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
