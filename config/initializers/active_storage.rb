# Configure Active Storage for production
if Rails.env.production?
  Rails.application.configure do
    # Set the host for Active Storage URLs in production
    config.active_storage.variant_processor = :mini_magick
    
    # Configure Active Storage to serve files from the Rails app
    config.active_storage.draw_routes = true
    config.active_storage.resolve_model_to_route = :rails_storage_proxy
    
    # Set the host for Active Storage URLs
    config.active_storage.url_expires_in = 1.hour
  end
end