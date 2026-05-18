class AddSourceToBankDeposits < ActiveRecord::Migration[7.1]
  def change
    add_column :bank_deposits, :source, :string, null: false, default: "freee"
    add_index :bank_deposits, :source
  end
end
