class ImageUploader < CarrierWave::Uploader::Base
  # Include MiniMagick support:
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if Rails.env.production?
      # Use tmp/uploads which symlinks to Railway Volume in production
      "tmp/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    else
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end

  # Process files as they are uploaded:
  # process resize_to_fit: [1200, 1200]

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fill: [300, 300]
  # end

  # version :medium do
  #   process resize_to_fit: [600, 600]
  # end

  # Add an allowlist of extensions which are allowed to be uploaded.
  def extension_allowlist
    %w(jpg jpeg gif png webp)
  end

  # Override the filename of the uploaded files:
  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
end
