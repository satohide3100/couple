class CouplePhoto < ApplicationRecord
  mount_uploader :image, ImageUploader
  
  scope :background_photos, -> { where(is_background: true) }
  scope :regular_photos, -> { where(is_background: false) }
  
  def self.current_background
    background_photos.order(created_at: :desc).first
  end
end
