class AddMerchandisingToProducts < ActiveRecord::Migration[8.1]
  def change
    # The regular price the product is marked down from; nil when it isn't on sale.
    add_column :products, :compare_at_price_cents, :integer
    # Aggregates of reviews, kept by Reviews::CreateService so listings can
    # sort and filter by rating without a join.
    add_column :products, :reviews_count, :integer, null: false, default: 0
    add_column :products, :rating_average, :decimal, precision: 2, scale: 1, null: false, default: 0

    add_check_constraint :products, "compare_at_price_cents IS NULL OR compare_at_price_cents > price_cents",
      name: "products_compare_at_above_price"
  end
end
