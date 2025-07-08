class AddImageToCouplePhotos < ActiveRecord::Migration[7.1]
  def change
    add_column :couple_photos, :image, :string
  end
end
