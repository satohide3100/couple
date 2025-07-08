class ApplicationController < ActionController::Base
  # CSRF対策（LIFFトークン検証で代替）
  protect_from_forgery with: :exception, unless: -> { request.xhr? }

  before_action :set_csrf_token_header

  # アップロードされたファイルの配信（本番環境用）
  def serve_file
    if Rails.env.production?
      # Try both uploads and tmp/uploads paths
      file_path = Rails.root.join('uploads', params[:path])
      tmp_file_path = Rails.root.join('tmp', 'uploads', params[:path])
      
      # デバッグログを追加
      Rails.logger.info "=== File Serve Debug ==="
      Rails.logger.info "Requested path: #{params[:path]}"
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
        # List directories for debugging
        ['uploads', 'tmp/uploads'].each do |dir|
          full_dir = Rails.root.join(dir)
          if Dir.exist?(full_dir)
            Rails.logger.info "#{dir} directory contents: #{Dir.entries(full_dir)}"
          else
            Rails.logger.info "Directory does not exist: #{full_dir}"
          end
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
