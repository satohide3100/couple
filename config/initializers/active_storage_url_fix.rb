# Fix Active Storage URL generation for production
if Rails.env.production?
  Rails.application.config.after_initialize do
    # Override the default URL generation for Active Storage
    ActiveStorage::Current.url_options = {
      host: ENV['RAILWAY_PUBLIC_DOMAIN'] || 'localhost:3000',
      protocol: 'https'
    }
  end
end