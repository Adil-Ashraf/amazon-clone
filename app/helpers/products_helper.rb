module ProductsHelper
  def stock_badge(product)
    if product.out_of_stock?
      status_pill("Sold out", "bg-danger-soft text-danger")
    elsif product.low_stock?
      status_pill("Only #{product.stock} left", "bg-warn-soft text-warn-strong")
    else
      status_pill("In stock", "bg-success-soft text-success")
    end
  end

  # Five stars filled to the product's average, plus the number and count.
  # Nothing is drawn for a product nobody has reviewed yet: empty stars
  # would read as a bad rating.
  def rating_summary(product, size: :sm, link: nil)
    return content_tag(:p, "No reviews yet", class: "text-sm text-muted") unless product.reviewed?

    average = product.rating_average.to_f
    count = product.reviews_count
    text_class = size == :lg ? "text-[15px]" : "text-sm"

    summary = safe_join([
      rating_stars(average, css_class: size == :lg ? "size-[18px]" : "size-4"),
      content_tag(:span, format("%.1f", average), class: "font-semibold text-ink tabular-nums", "aria-hidden": "true"),
      content_tag(:span, "(#{number_with_delimiter(count)})", class: "text-muted tabular-nums", "aria-hidden": "true"),
      content_tag(:span, "Rated #{format('%.1f', average)} out of 5 from #{pluralize(count, 'review')}", class: "sr-only")
    ])

    classes = "inline-flex items-center gap-1.5 #{text_class}"
    link ? link_to(summary, link, class: "#{classes} rounded hover:underline underline-offset-4 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand") : content_tag(:div, summary, class: classes)
  end

  # Two rows of stars stacked: an outline row, and a filled row clipped to
  # the average. Decorative; callers give the number in text.
  def rating_stars(average, css_class: "size-4")
    row = ->(fill) do
      content_tag(:span, class: "flex gap-0.5") do
        safe_join(5.times.map { icon(:star, css_class: "#{css_class} shrink-0 #{fill}", stroke_width: 1.5) })
      end
    end

    content_tag(:span, class: "relative inline-flex", "aria-hidden": "true") do
      concat row.call("text-line fill-line")
      concat content_tag(:span, row.call("text-brand fill-brand"),
        class: "absolute inset-y-0 left-0 overflow-hidden", style: "width: #{(average.clamp(0, 5) / 5.0 * 100).round(1)}%")
    end
  end

  # Current price in ink, and the regular price struck through when it's on
  # sale -- the strike-through is the sale signal, so prices stay calm.
  def price_tag(product, size: :md)
    price_class = { sm: "text-base", md: "text-lg sm:text-xl", lg: "text-[28px] lg:text-[32px]" }.fetch(size)

    content_tag(:p, class: "flex flex-wrap items-baseline gap-x-2 gap-y-1") do
      concat content_tag(:span, format_price_cents(product.price_cents), class: "price #{price_class}")
      if product.on_sale?
        concat content_tag(:span, safe_join([
          content_tag(:span, "Regular price", class: "sr-only"),
          format_price_cents(product.compare_at_price_cents)
        ]), class: "text-sm text-muted line-through tabular-nums")
      end
    end
  end

  def discount_badge(product, size: :sm)
    return unless product.on_sale?

    size_class = size == :md ? "px-3 py-1 text-sm" : "px-2 py-0.5 text-[11px] leading-4"
    content_tag :span, "−#{product.discount_percent}%",
      class: "inline-flex items-center rounded-full bg-brand font-semibold text-ink tabular-nums #{size_class}",
      "aria-label": "#{product.discount_percent}% off"
  end

  # Width hints for srcset, one per place a product image is shown.
  IMAGE_SIZES = {
    card: "(min-width: 1280px) 290px, (min-width: 1024px) 23vw, (min-width: 768px) 31vw, 48vw",
    detail: "(min-width: 1024px) 600px, (min-width: 768px) 50vw, 100vw",
    hero: "(min-width: 1024px) 300px, (min-width: 640px) 45vw, 100vw",
    thumb: "120px"
  }.freeze
  UNSPLASH_WIDTHS = [ 400, 600, 900, 1200 ].freeze
  # Warm neutrals for the no-photo tile, picked per category so neighbours differ.
  TILE_BACKGROUNDS = %w[bg-bg bg-subtle bg-brand-soft bg-stone].freeze

  # A product's image inside the caller's fixed-size box (grid card, product
  # page, cart, orders). While the photo loads the box is a neutral `subtle`
  # well. The designed tile (category icon + first words of the name) is
  # rendered hidden and only shown when there is no photo or it fails to
  # load (product-image Stimulus controller). We never show a photo of a
  # different item. Unsplash photos get a srcset so a 250px card downloads a
  # ~600px file, not the 1200px original; image_url itself is unchanged.
  def product_image_tag(product, alt: nil, css_class: nil, loading: "lazy", sizes: :card)
    name = alt || product.name
    wrapper_class = "@container relative w-full h-full overflow-hidden bg-subtle"
    has_photo = product.image_url.present?
    tile = product_tile(product, name: name, covered: has_photo)
    return content_tag(:div, tile, class: wrapper_class) unless has_photo

    photo = image_tag(product_image_src(product.image_url, 600), alt: name, loading: loading, decoding: "async",
      srcset: product_image_srcset(product.image_url), sizes: IMAGE_SIZES.fetch(sizes),
      class: [ "absolute inset-0 w-full h-full object-cover", css_class ].compact.join(" "),
      data: { product_image_target: "photo", action: "error->product-image#fallback" })

    content_tag :div, safe_join([ tile, photo ]), class: wrapper_class, data: { controller: "product-image" }
  end

  private

  def unsplash?(url)
    URI.parse(url).host == "images.unsplash.com"
  rescue URI::InvalidURIError
    false
  end

  # The same Unsplash photo at another width (their CDN resizes on the fly).
  def product_image_src(url, width)
    return url unless unsplash?(url)

    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query.to_s).to_h.merge("w" => width.to_s)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def product_image_srcset(url)
    return unless unsplash?(url)

    UNSPLASH_WIDTHS.map { |width| "#{product_image_src(url, width)} #{width}w" }.join(", ")
  end

  # The designed tile. `covered` means a photo sits on top of it, so the tile
  # stays hidden (and out of the accessibility tree) until the photo fails.
  def product_tile(product, name:, covered:)
    category = product.category
    glyph = category_icon(category, css_class: "size-[34%] text-brand-strong/80", stroke_width: 1)

    label = content_tag(:span, product.name.split.first(3).join(" "),
      class: "absolute bottom-3 left-3 right-3 hidden truncate text-sm font-medium text-muted-strong @[12rem]:block",
      "aria-hidden": "true")

    # alt: "" means the caller shows the image as decoration.
    decorative = name.blank?

    content_tag :div, safe_join([ glyph, label ]),
      role: (decorative ? nil : "img"), "aria-label": name.presence, "aria-hidden": (covered || decorative ? "true" : nil),
      hidden: covered,
      class: "flex w-full h-full items-center justify-center #{TILE_BACKGROUNDS[category.id.to_i % TILE_BACKGROUNDS.size]}",
      data: (covered ? { product_image_target: "tile" } : nil)
  end
end
