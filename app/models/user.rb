class User < ApplicationRecord
  has_secure_password

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy

  before_validation :downcase_email

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
