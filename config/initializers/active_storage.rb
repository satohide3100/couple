# Configure Active Storage for production
Rails.application.configure do
  # Set the host for Active Storage URLs in production
  config.active_storage.variant_processor = :mini_magick if Rails.env.production?
  
  # Configure Active Storage to serve files from the Rails app
  if Rails.env.production?
    config.active_storage.draw_routes = true
    config.active_storage.resolve_model_to_route = :rails_storage_proxy
  end
end