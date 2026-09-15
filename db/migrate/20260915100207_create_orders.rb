class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :total_cents, null: false
      t.string :shipping_name, null: false
      t.string :shipping_address_line1, null: false
      t.string :shipping_address_line2
      t.string :shipping_city, null: false
      t.string :shipping_state, null: false
      t.string :shipping_zip, null: false

      t.timestamps
    end
  end
end
