module ProductsHelper
  def stock_badge(product)
    if product.out_of_stock?
      content_tag :span, "Out of Stock", class: "text-sm font-medium text-red-600"
    elsif product.low_stock?
      content_tag :span, "Only #{product.stock} left", class: "text-sm font-medium text-amber-600"
    else
      content_tag :span, "In Stock", class: "text-sm font-medium text-green-700"
    end
  end
end
