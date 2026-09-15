module ProductsHelper
  def stock_badge(product)
    if product.out_of_stock?
      stock_badge_pill("Out of Stock", "bg-red-100 text-red-800")
    elsif product.low_stock?
      stock_badge_pill("Only #{product.stock} left", "bg-amber-100 text-amber-800")
    else
      stock_badge_pill("In Stock", "bg-green-100 text-green-800")
    end
  end

  private

  def stock_badge_pill(text, color_classes)
    content_tag :span, class: "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold #{color_classes}" do
      concat content_tag(:span, "", class: "w-1.5 h-1.5 rounded-full bg-current")
      concat text
    end
  end
end
