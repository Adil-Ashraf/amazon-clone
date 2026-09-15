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

  # Renders the product's real photo (image_url), falling back client-side to
  # a generated colored icon card if that photo fails to load -- e.g. the
  # keyword-matched photo service is down, or a specific keyword has no match.
  def product_image_tag(product, **options)
    fallback = product_image_fallback_data_uri(product)
    options[:onerror] = "this.onerror=null;this.src='#{fallback}';"
    image_tag product.image_url, **options
  end

  # The same colored icon + category color + wrapped product name design used
  # before real photos were added, kept as the fallback for a broken/missing
  # photo rather than removed.
  def product_image_fallback_data_uri(product)
    category = product.category
    icon_inner = CategoriesHelper::ICON_PATHS.fetch(category.icon_key, CategoriesHelper::ICON_PATHS[Category::DEFAULT_ICON_KEY])
    lines = wrap_for_fallback_card(product.name, 20).first(3)

    text_svg = lines.each_with_index.map do |line, i|
      y = 236 + (i * 26)
      %(<text x="200" y="#{y}" font-family="Helvetica, Arial, sans-serif" font-size="19" font-weight="600" fill="#ffffff" text-anchor="middle">#{ERB::Util.html_escape(line)}</text>)
    end.join

    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="640" height="480" viewBox="0 0 400 300">
        <rect width="400" height="300" fill="#{category.color_hex}"/>
        <rect width="400" height="300" fill="#000000" opacity="0.08"/>
        <g transform="translate(152,58) scale(4)" color="#ffffff" fill="none" stroke="#ffffff" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round">
          #{icon_inner}
        </g>
        #{text_svg}
      </svg>
    SVG

    "data:image/svg+xml,#{ERB::Util.url_encode(svg)}"
  end

  private

  def wrap_for_fallback_card(text, max_chars)
    lines = []
    current = +""

    text.split(" ").each do |word|
      candidate = current.empty? ? word : "#{current} #{word}"
      if candidate.length > max_chars && !current.empty?
        lines << current
        current = +word
      else
        current = candidate
      end
    end
    lines << current unless current.empty?
    lines
  end

  def stock_badge_pill(text, color_classes)
    content_tag :span, class: "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold #{color_classes}" do
      concat content_tag(:span, "", class: "w-1.5 h-1.5 rounded-full bg-current")
      concat text
    end
  end
end
