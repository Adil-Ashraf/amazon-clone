module ProductsHelper
  PAGE_BG_RGB = [ 0xFA, 0xF8, 0xF5 ].freeze # the bg token in docs/DESIGN.md

  def stock_badge(product)
    if product.out_of_stock?
      stock_badge_pill("Sold out", "bg-danger-soft text-danger")
    elsif product.low_stock?
      stock_badge_pill("Only #{product.stock} left", "bg-warn-soft text-warn")
    else
      stock_badge_pill("In stock", "bg-accent-soft text-accent")
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

  # A product's image inside the caller's fixed-size box (grid card, product
  # page, bag, orders). The designed tile -- a light tint of the category
  # colour, the category's line icon and the first words of the name -- is
  # always rendered. When the product has a verified photo (image_url, see
  # db/seeds/product_images.yml) it is layered on top with object-cover, and
  # the tile is hidden from assistive tech; if the photo fails to load, the
  # product-image Stimulus controller removes it and the tile shows through
  # with no layout shift. We never show a photo of a different item: that
  # would be a fake signal (docs/DESIGN.md).
  def product_image_tag(product, alt: nil, css_class: nil, loading: "lazy")
    name = alt || product.name
    wrapper_class = "@container relative w-full h-full overflow-hidden"
    tile = product_tile(product, name: name, css_class: css_class, covered: product.image_url.present?)
    return content_tag(:div, tile, class: wrapper_class) if product.image_url.blank?

    photo = image_tag(product.image_url, alt: name, loading: loading, decoding: "async",
      class: [ "absolute inset-0 w-full h-full object-cover", css_class ].compact.join(" "),
      data: { product_image_target: "photo", action: "error->product-image#fallback" })

    content_tag :div, safe_join([ tile, photo ]), class: wrapper_class, data: { controller: "product-image" }
  end

  private

  # The designed tile. `covered` means a photo sits on top of it, so the tile
  # is hidden from assistive tech until the photo fails.
  def product_tile(product, name:, css_class:, covered:)
    category = product.category
    icon_inner = CategoriesHelper::ICON_PATHS.fetch(category.icon_key, CategoriesHelper::ICON_PATHS[Category::DEFAULT_ICON_KEY])

    icon = content_tag(:svg, icon_inner.html_safe,
      class: "size-[40%]", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      "stroke-width": "1", "stroke-linecap": "round", "stroke-linejoin": "round",
      "aria-hidden": "true", style: "color: #{category.color_hex}")

    label = content_tag(:span, product.name.split.first(3).join(" "),
      class: "absolute bottom-3 left-3 right-3 hidden truncate font-display text-lg leading-tight text-ink/70 @[12rem]:block",
      "aria-hidden": "true")

    content_tag :div, safe_join([ icon, label ]),
      role: "img", "aria-label": name, "aria-hidden": (covered ? "true" : nil),
      class: [ "flex w-full h-full items-center justify-center", css_class ].compact.join(" "),
      style: "background-color: #{category_tint(category.color_hex)}",
      data: (covered ? { product_image_target: "tile" } : nil)
  end

  # The category colour mixed into the page background at low strength, so
  # every tile is a soft, low-saturation wash of its category.
  def category_tint(hex, strength: 0.12)
    rgb = hex.delete("#").scan(/../).map { |pair| pair.to_i(16) }
    mixed = rgb.zip(PAGE_BG_RGB).map { |color, bg| (bg + (color - bg) * strength).round }
    format("#%02x%02x%02x", *mixed)
  end

  def stock_badge_pill(text, color_classes)
    content_tag :span, class: "pill #{color_classes}" do
      concat content_tag(:span, "", class: "w-1.5 h-1.5 rounded-full bg-current")
      concat text
    end
  end
end
