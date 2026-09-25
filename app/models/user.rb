class User < ApplicationRecord
  has_secure_password

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy

  before_validation :downcase_email

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  # A real purchase: paid for and not cancelled. Gates who may review.
  def purchased?(product)
    orders.where.not(status: %i[pending cancelled])
      .joins(:order_items).where(order_items: { product_id: product.id }).exists?
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
