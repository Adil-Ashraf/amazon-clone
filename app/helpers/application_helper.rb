module ApplicationHelper
  def format_price_cents(cents)
    number_to_currency(cents / 100.0)
  end

  # Shared visual treatment for a plain text/email/password/number input: a
  # real border (not just a border color with no width, which renders
  # invisible), a white background so text stays legible even in system dark
  # mode, and a visible amber focus ring. Callers add their own width/padding.
  def input_classes
    "rounded border border-gray-300 bg-white text-gray-900 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-amber-400"
  end

  # The one "card" look used for every card-like container on the site
  # (product tiles, the buy box, order/cart summaries, auth forms, empty
  # states): white background, subtle border, small shadow. Callers add
  # their own padding/spacing/layout classes.
  def card_classes(extra = nil)
    [ "bg-white rounded border border-gray-200 shadow-sm", extra ].compact.join(" ")
  end
end
