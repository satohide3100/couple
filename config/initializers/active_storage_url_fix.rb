# Fix Active Storage URL generation for production
# This will be set after Rails is fully loaded
if Rails.env.production?
  Rails.application.config.to_prepare do
    ActiveStorage::Current.url_options = {
      host: ENV['RAILWAY_PUBLIC_DOMAIN'] || 'localhost:3000',
      protocol: 'https'
    }
  end
end