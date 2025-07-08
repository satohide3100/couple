class CouplePhoto < ApplicationRecord
  has_one_attached :image
  
  
  scope :background_photos, -> { where(is_background: true) }
  scope :regular_photos, -> { where(is_background: false) }
  
  def self.current_background
    background_photos.order(created_at: :desc).first
  end
end
