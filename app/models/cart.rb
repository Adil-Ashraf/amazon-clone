class Cart < ApplicationRecord
  belongs_to :user

  has_many :cart_items, dependent: :destroy

  def total_cents
    cart_items.includes(:product).sum { |item| item.product.price_cents * item.quantity }
  end
end
