class NewsletterSubscription < ApplicationRecord
  before_validation :normalize_email

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  private

  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
end
