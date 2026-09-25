module CategoriesHelper
  # Simple Heroicons-outline-style glyphs (24x24 viewBox, stroke-based) keyed
  # by Category#icon_key. Shared between the category chips and the
  # designed product tiles (ProductsHelper#product_image_tag).
  ICON_PATHS = {
    chip: <<~SVG,
      <rect x="6" y="6" width="12" height="12" rx="2"/>
      <line x1="9" y1="1" x2="9" y2="6"/>
      <line x1="15" y1="1" x2="15" y2="6"/>
      <line x1="9" y1="18" x2="9" y2="23"/>
      <line x1="15" y1="18" x2="15" y2="23"/>
      <line x1="1" y1="9" x2="6" y2="9"/>
      <line x1="1" y1="15" x2="6" y2="15"/>
      <line x1="18" y1="9" x2="23" y2="9"/>
      <line x1="18" y1="15" x2="23" y2="15"/>
    SVG
    house: <<~SVG,
      <path d="M3 11 L12 3 L21 11"/>
      <path d="M5 10 V21 H19 V10"/>
      <rect x="10" y="14" width="4" height="7"/>
    SVG
    book: <<~SVG,
      <rect x="4" y="4" width="7" height="16" rx="1"/>
      <rect x="13" y="4" width="7" height="16" rx="1"/>
    SVG
    shirt: <<~SVG,
      <path d="M8 4 L4 8 L7 11 L8 10 V20 H16 V10 L17 11 L20 8 L16 4 L12 6 L8 4 Z"/>
    SVG
    dumbbell: <<~SVG,
      <rect x="1" y="9" width="3" height="6" rx="1"/>
      <rect x="20" y="9" width="3" height="6" rx="1"/>
      <rect x="6" y="7" width="2" height="10"/>
      <rect x="16" y="7" width="2" height="10"/>
      <line x1="8" y1="12" x2="16" y2="12"/>
    SVG
    droplet: <<~SVG,
      <path d="M12 2 C12 2 6 11 6 15 A6 6 0 0 0 18 15 C18 11 12 2 12 2 Z"/>
    SVG
    dice: <<~SVG,
      <rect x="4" y="4" width="16" height="16" rx="3"/>
      <circle cx="8" cy="8" r="1.3" fill="currentColor" stroke="none"/>
      <circle cx="16" cy="8" r="1.3" fill="currentColor" stroke="none"/>
      <circle cx="12" cy="12" r="1.3" fill="currentColor" stroke="none"/>
      <circle cx="8" cy="16" r="1.3" fill="currentColor" stroke="none"/>
      <circle cx="16" cy="16" r="1.3" fill="currentColor" stroke="none"/>
    SVG
    briefcase: <<~SVG,
      <rect x="3" y="7" width="18" height="12" rx="2"/>
      <path d="M8 7 V5 a2 2 0 0 1 2 -2 h4 a2 2 0 0 1 2 2 V7"/>
      <line x1="3" y1="12" x2="21" y2="12"/>
    SVG
    tag: <<~SVG
      <path d="M20 12 L12 20 L4 12 L4 4 L12 4 Z"/>
      <circle cx="8" cy="8" r="1.3" fill="currentColor" stroke="none"/>
    SVG
  }.freeze

  def category_icon(category, css_class: "w-5 h-5")
    inner = ICON_PATHS.fetch(category.icon_key, ICON_PATHS[Category::DEFAULT_ICON_KEY])
    content_tag(:svg, inner.html_safe,
      class: css_class, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      "stroke-width": "2", "stroke-linecap": "round", "stroke-linejoin": "round",
      "aria-hidden": "true")
  end
end
