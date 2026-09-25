module ApplicationHelper
  # trim: true drops ".00" for promotional copy ("Free shipping over $50");
  # transaction amounts always keep their cents.
  def format_price_cents(cents, trim: false)
    number_to_currency(cents / 100.0, precision: trim && (cents % 100).zero? ? 0 : 2)
  end

  # The .input component class (docs/DESIGN.md) for text/email/password/number
  # fields. Callers add their own width.
  def input_classes
    "input"
  end

  # The .card component class (docs/DESIGN.md) for every card-like container.
  # Callers add their own padding/spacing/layout classes.
  def card_classes(extra = nil)
    [ "card", extra ].compact.join(" ")
  end
end
