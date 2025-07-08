class CreatePlaces < ActiveRecord::Migration[7.1]
  def change
    create_table :places do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.text :memo
      t.boolean :visited, default: false, null: false
      t.integer :position

      t.timestamps
    end

    add_index :places, :position
    add_index :places, :visited
  end
end
