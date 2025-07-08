CarrierWave.configure do |config|
  config.storage = :file
  config.asset_host = ActionController::Base.asset_host
  
  # すべての環境でRailsルートを使用
  config.root = Rails.root
  
  # 画像処理のバックエンド設定
  config.cache_storage = :file
  config.cache_dir = "#{Rails.root}/tmp/uploads"
end