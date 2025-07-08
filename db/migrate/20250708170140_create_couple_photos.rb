class CreateCouplePhotos < ActiveRecord::Migration[7.1]
  def change
    create_table :couple_photos do |t|
      t.string :title
      t.text :description
      t.boolean :is_background, default: false
      t.datetime :taken_at

      t.timestamps
    end
  end
end
