class Product < ApplicationRecord
  include PgSearch::Model

  belongs_to :category

  has_many :order_items, dependent: :restrict_with_error
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :compare_at_price_cents, numericality: { only_integer: true, greater_than: :price_cents },
    allow_nil: true, if: :price_cents

  pg_search_scope :search_full_text,
    against: [ :name, :description ],
    using: { tsearch: { prefix: true } }

  LOW_STOCK_THRESHOLD = 5

  scope :in_stock, -> { where("stock > 0") }
  scope :on_sale, -> { where.not(compare_at_price_cents: nil) }
  scope :with_photo, -> { where.not(image_url: nil) }
  scope :top_rated, -> { order(rating_average: :desc, reviews_count: :desc, id: :asc) }
  # Units sold first, then how many people reviewed it.
  scope :popular, -> {
    left_joins(:order_items).group(:id)
      .order(Arel.sql("COALESCE(SUM(order_items.quantity), 0) DESC"), reviews_count: :desc, id: :asc)
  }

  def out_of_stock?
    stock <= 0
  end

  def low_stock?
    stock.positive? && stock <= LOW_STOCK_THRESHOLD
  end

  def on_sale?
    compare_at_price_cents.present?
  end

  def discount_percent
    return 0 unless on_sale?

    ((compare_at_price_cents - price_cents) * 100.0 / compare_at_price_cents).round
  end

  def reviewed?
    reviews_count.positive?
  end
end
