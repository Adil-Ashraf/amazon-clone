class Cart < ApplicationRecord
  belongs_to :user

  has_many :cart_items, dependent: :destroy

  def subtotal_cents
    cart_items.includes(:product).sum { |item| item.product.price_cents * item.quantity }
  end

  def shipping_cents
    Order.shipping_cents_for(subtotal_cents)
  end

  def total_cents
    subtotal_cents + shipping_cents
  end
end
