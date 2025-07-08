class AddIconImageToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :icon_image, :string
  end
end
