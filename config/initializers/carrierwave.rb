CarrierWave.configure do |config|
  config.storage = :file
  config.asset_host = ActionController::Base.asset_host
  
  # 本番環境でのアップロードディレクトリ設定
  if Rails.env.production?
    config.root = Rails.root.join('public')
    # Ensure uploads directory exists and is writable
    uploads_dir = Rails.root.join('public', 'uploads')
    FileUtils.mkdir_p(uploads_dir) unless Dir.exist?(uploads_dir)
  else
    config.root = Rails.root
  end
  
  # 画像処理のバックエンド設定
  config.cache_storage = :file
  config.cache_dir = "#{Rails.root}/tmp/uploads"
end