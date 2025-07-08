class ApplicationController < ActionController::Base
  # CSRF対策（LIFFトークン検証で代替）
  protect_from_forgery with: :exception, unless: -> { request.xhr? }

  before_action :set_csrf_token_header

  # アップロードされたファイルの配信（本番環境用）
  def serve_file
    if Rails.env.production?
      # パスに拡張子を追加
      path_with_ext = params[:path].include?('.') ? params[:path] : "#{params[:path]}.jpeg"
      
      # Try both uploads and tmp/uploads paths
      file_path = Rails.root.join('uploads', path_with_ext)
      tmp_file_path = Rails.root.join('tmp', 'uploads', path_with_ext)
      
      # デバッグログを追加
      Rails.logger.info "=== File Serve Debug ==="
      Rails.logger.info "Original path: #{params[:path]}"
      Rails.logger.info "Path with extension: #{path_with_ext}"
      Rails.logger.info "File path: #{file_path}"
      Rails.logger.info "Tmp file path: #{tmp_file_path}"
      Rails.logger.info "File exists: #{File.exist?(file_path)}"
      Rails.logger.info "Tmp file exists: #{File.exist?(tmp_file_path)}"
      
      # Check both possible locations
      actual_file_path = File.exist?(file_path) ? file_path : tmp_file_path
      
      if File.exist?(actual_file_path)
        Rails.logger.info "Serving file from: #{actual_file_path}"
        send_file actual_file_path, disposition: 'inline'
      else
        Rails.logger.info "File not found in either location"
        # List the actual directory contents to see what files exist
        base_dir = File.dirname(file_path)
        if Dir.exist?(base_dir)
          Rails.logger.info "Directory #{base_dir} contents: #{Dir.entries(base_dir)}"
        end
        tmp_base_dir = File.dirname(tmp_file_path)
        if Dir.exist?(tmp_base_dir)
          Rails.logger.info "Directory #{tmp_base_dir} contents: #{Dir.entries(tmp_base_dir)}"
        end
        render plain: "File not found", status: 404
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
