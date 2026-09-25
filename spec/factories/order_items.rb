FactoryBot.define do
  factory :order_item do
    order
    product
    quantity { 1 }
    price_cents { product.price_cents }
  end
end
