source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Rails フレームワーク
gem "rails", "~> 7.1.3"
gem "sprockets-rails"
gem "sqlite3", "~> 1.4"
gem "puma", ">= 5.0"

# JavaScript/CSS バンドリング
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"

# 並び替え機能
gem "acts_as_list"

# Redis アダプター（Turbo Streams用）
gem "redis", "~> 5.0"

# 環境変数管理
gem "dotenv-rails", groups: [:development, :test]

# Windows タイムゾーンサポート
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# 起動時間短縮
gem "bootsnap", ">= 1.4.4", require: false

# CORS対応
gem "rack-cors"

group :development, :test do
  # デバッグツール
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  
  # テスト関連
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  # 開発効率化
  gem "web-console"
  
  # コード品質
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "standard"
end

group :test do
  # システムテスト
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end