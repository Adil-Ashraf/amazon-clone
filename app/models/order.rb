class Order < ApplicationRecord
  belongs_to :user

  has_many :order_items, dependent: :destroy

  FREE_SHIPPING_THRESHOLD_CENTS = 5_000
  SHIPPING_FEE_CENTS = 599

  enum :status, { pending: 0, paid: 1, shipped: 2, out_for_delivery: 3, delivered: 4, cancelled: 5 }

  # Status filters on the orders page -> the statuses each one covers.
  STATUS_GROUPS = {
    "processing" => %w[pending paid],
    "shipped" => %w[shipped out_for_delivery],
    "delivered" => %w[delivered],
    "cancelled" => %w[cancelled]
  }.freeze

  validates :total_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :shipping_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :shipping_name, :shipping_address_line1, :shipping_city, :shipping_state, :shipping_zip, presence: true

  def self.shipping_cents_for(subtotal_cents)
    subtotal_cents >= FREE_SHIPPING_THRESHOLD_CENTS ? 0 : SHIPPING_FEE_CENTS
  end

  def subtotal_cents
    total_cents - shipping_cents
  end
end
