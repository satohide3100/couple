require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Couple
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # タイムゾーン設定
    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :local

    # 日本語設定
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [:ja, :en]
    

    # CORS 設定（LIFF用）
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "https://liff.line.me",
                "https://c8df08fb4cfe.ngrok-free.app",
                "https://*.ngrok-free.app"
        resource "*",
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end
  end
end
