class AddShippingCentsToOrders < ActiveRecord::Migration[8.1]
  def change
    # Purchase-time snapshot of the shipping charge; total_cents includes it.
    add_column :orders, :shipping_cents, :integer, null: false, default: 0
  end
end
