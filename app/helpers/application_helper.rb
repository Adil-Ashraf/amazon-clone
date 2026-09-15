module ApplicationHelper
  def format_price_cents(cents)
    number_to_currency(cents / 100.0)
  end
end
