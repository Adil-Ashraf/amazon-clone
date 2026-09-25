module ApplicationHelper
  def format_price_cents(cents)
    number_to_currency(cents / 100.0)
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
