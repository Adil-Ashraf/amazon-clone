module ApplicationHelper
  # trim: true drops ".00" for promotional copy ("Free shipping over $50");
  # transaction amounts always keep their cents.
  def format_price_cents(cents, trim: false)
    number_to_currency(cents / 100.0, precision: trim && (cents % 100).zero? ? 0 : 2)
  end

  # The .pill status badge (docs/DESIGN.md): a dot plus a label, e.g. stock
  # or order status. color_classes sets the tone ("bg-success-soft text-success").
  def status_pill(text, color_classes)
    content_tag :span, class: "pill #{color_classes}" do
      concat content_tag(:span, "", class: "size-1.5 rounded-full bg-current")
      concat text
    end
  end
end
