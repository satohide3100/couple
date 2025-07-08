class AddPositionToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :position, :integer
  end
end
