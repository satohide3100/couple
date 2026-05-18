class CreateFreeeCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :freee_credentials do |t|
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.string :company_id
      t.timestamps
    end
  end
end
