CarrierWave.configure do |config|
  config.storage = :file
  config.asset_host = ActionController::Base.asset_host
  
  # すべての環境でRailsルートを使用
  config.root = Rails.root
  
  # 画像処理のバックエンド設定
  config.cache_storage = :file
  config.cache_dir = "#{Rails.root}/tmp/uploads"
  
  # 本番環境でのVolumeディレクトリ確保
  if Rails.env.production?
    uploads_dir = Rails.root.join('storage', 'uploads')
    FileUtils.mkdir_p(uploads_dir) unless Dir.exist?(uploads_dir)
  end
end