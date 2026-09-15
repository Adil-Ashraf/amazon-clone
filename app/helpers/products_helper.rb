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

  # A realistic-looking (but not real, no logistics behind it) delivery
  # estimate, recomputed from today's date each render rather than hardcoded
  # so it never looks stale.
  def estimated_delivery_range
    start_date = 3.days.from_now.to_date
    end_date = 5.days.from_now.to_date
    "#{start_date.strftime('%a, %b %-d')} – #{end_date.strftime('%a, %b %-d')}"
  end

  # Every product shows one of its category's verified representative photos
  # (Category#representative_image_url -- hardcoded, hand-checked Unsplash
  # URLs, not a per-product keyword search that could return anything),
  # picked deterministically per product so sibling products don't all show
  # the identical photo. Renders as two stacked layers filling the caller's
  # fixed-size container (the caller is always a fixed-width/height or
  # aspect-ratio div -- product grid card, detail page, cart line item, order
  # line item): a generated colored tile (category color + icon) underneath,
  # sized with object-contain since it's a centered icon that must never be
  # cropped, and the real photo on top sized with object-cover so it always
  # fills the box edge-to-edge regardless of its native aspect ratio. If the
  # real photo fails to load, onerror hides it, revealing the tile beneath --
  # the box itself never changes size or shape either way.
  def product_image_tag(product, **options)
    category = product.category
    alt_text = options.delete(:alt) || product.name
    extra_class = options.delete(:class)
    real_url = category.representative_image_url(product.id)

    fallback_img = image_tag product_image_data_uri(product), alt: "", aria: { hidden: true },
      class: "absolute inset-0 w-full h-full object-contain"

    real_img = if real_url
      image_tag real_url, **options, alt: alt_text,
        class: [ "absolute inset-0 w-full h-full object-cover", extra_class ].compact.join(" "),
        onerror: "this.style.display='none';"
    end

    content_tag :div, safe_join([ fallback_img, real_img ].compact),
      class: "relative w-full h-full overflow-hidden", style: "background-color: #{category.color_hex}"
  end

  private

  def product_image_data_uri(product)
    category = product.category
    icon_inner = CategoriesHelper::ICON_PATHS.fetch(category.icon_key, CategoriesHelper::ICON_PATHS[Category::DEFAULT_ICON_KEY])

    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="640" height="480" viewBox="0 0 400 300">
        <rect width="400" height="300" fill="#{category.color_hex}"/>
        <rect width="400" height="300" fill="#000000" opacity="0.08"/>
        <g transform="translate(152,102) scale(4)" color="#ffffff" fill="none" stroke="#ffffff" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round">
          #{icon_inner}
        </g>
      </svg>
    SVG

    "data:image/svg+xml,#{ERB::Util.url_encode(svg)}"
  end

  def stock_badge_pill(text, color_classes)
    content_tag :span, class: "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold #{color_classes}" do
      concat content_tag(:span, "", class: "w-1.5 h-1.5 rounded-full bg-current")
      concat text
    end
  end
end
