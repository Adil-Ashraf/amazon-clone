# This file seeds a realistic catalog so the app doesn't look empty on first run.
# Safe to run repeatedly: everything is looked up with find_or_create_by!.

# Generates a colored placeholder image (category icon + wrapped product name)
# as an inline SVG data URI, instead of pulling random unrelated stock photos
# from an external API. Deterministic, so re-running seeds always produces the
# same image for the same product/category.
def placeholder_image_data_uri(product_name, category)
  icon_inner = CategoriesHelper::ICON_PATHS.fetch(category.icon_key, CategoriesHelper::ICON_PATHS[Category::DEFAULT_ICON_KEY])
  lines = wrap_for_placeholder(product_name, 20).first(3)

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

def wrap_for_placeholder(text, max_chars)
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

CATEGORIES_WITH_PRODUCTS = {
  "Electronics" => [
    { name: "Wireless Noise-Cancelling Headphones", description: "Over-ear Bluetooth headphones with active noise cancellation and 30-hour battery life.", price_cents: 19_999, stock: 48 },
    { name: "4K Ultra HD Smart TV 55-inch", description: "55-inch 4K smart TV with HDR support and built-in streaming apps.", price_cents: 54_999, stock: 15 },
    { name: "Portable Bluetooth Speaker", description: "Compact waterproof speaker with 12 hours of playtime and deep bass.", price_cents: 5_999, stock: 76 },
    { name: "USB-C Fast Charging Power Bank 20000mAh", description: "High-capacity power bank with USB-C PD fast charging for phones and tablets.", price_cents: 3_999, stock: 102 }
  ],
  "Home & Kitchen" => [
    { name: "Stainless Steel French Press Coffee Maker", description: "34oz French press with double-wall stainless steel construction for better heat retention.", price_cents: 3_499, stock: 60 },
    { name: "Non-Stick 12-Piece Cookware Set", description: "Complete non-stick cookware set including pots, pans, and lids, dishwasher safe.", price_cents: 12_999, stock: 22 },
    { name: "Robot Vacuum Cleaner with Mapping", description: "Smart robot vacuum with room mapping, app control, and automatic recharging.", price_cents: 24_999, stock: 18 },
    { name: "Electric Stand Mixer 5.5 Quart", description: "5.5-quart stand mixer with 10 speeds and dough hook, whisk, and paddle attachments.", price_cents: 18_999, stock: 25 }
  ],
  "Books" => [
    { name: "The Midnight Library", description: "A novel about the choices that go into a life well lived.", price_cents: 1_499, stock: 90 },
    { name: "Atomic Habits", description: "An easy and proven way to build good habits and break bad ones.", price_cents: 1_699, stock: 120 },
    { name: "A Brief History of Time", description: "A landmark volume in science writing on the origins and fate of the universe.", price_cents: 1_299, stock: 55 },
    { name: "The Silent Patient", description: "A psychological thriller about a woman's act of violence against her husband.", price_cents: 1_399, stock: 70 }
  ],
  "Clothing" => [
    { name: "Men's Classic Fit Oxford Shirt", description: "Breathable cotton oxford shirt with a classic fit, available in multiple colors.", price_cents: 2_999, stock: 85 },
    { name: "Women's High-Waisted Yoga Leggings", description: "Squat-proof high-waisted leggings with four-way stretch fabric.", price_cents: 2_499, stock: 110 },
    { name: "Unisex Fleece Pullover Hoodie", description: "Soft fleece hoodie with a kangaroo pocket and adjustable drawstring hood.", price_cents: 3_999, stock: 95 },
    { name: "Waterproof Hiking Jacket", description: "Lightweight waterproof shell jacket built for wet-weather hiking.", price_cents: 8_999, stock: 30 }
  ],
  "Sports & Outdoors" => [
    { name: "Adjustable Dumbbell Set 5-50 lbs", description: "Space-saving adjustable dumbbells that replace 15 sets of weights.", price_cents: 29_999, stock: 12 },
    { name: "2-Person Camping Tent", description: "Lightweight 3-season tent with easy setup and full rainfly coverage.", price_cents: 11_999, stock: 28 },
    { name: "Yoga Mat with Carrying Strap", description: "Extra-thick non-slip yoga mat with a built-in carrying strap.", price_cents: 2_299, stock: 130 },
    { name: "Insulated Stainless Steel Water Bottle 32oz", description: "Double-wall vacuum insulated bottle that keeps drinks cold for 24 hours.", price_cents: 1_999, stock: 150 }
  ],
  "Beauty & Personal Care" => [
    { name: "Vitamin C Brightening Serum", description: "Antioxidant-rich facial serum that brightens skin and reduces dark spots.", price_cents: 2_499, stock: 88 },
    { name: "Electric Rechargeable Toothbrush", description: "Sonic toothbrush with 5 cleaning modes and a 2-week battery life.", price_cents: 4_999, stock: 65 },
    { name: "Ceramic Hair Straightener", description: "Fast-heating ceramic plates with adjustable temperature settings.", price_cents: 3_499, stock: 40 },
    { name: "Nourishing Shea Butter Body Lotion", description: "Rich body lotion made with shea butter for 24-hour moisture.", price_cents: 1_299, stock: 140 }
  ],
  "Toys & Games" => [
    { name: "1000-Piece Jigsaw Puzzle: Mountain Landscape", description: "A challenging 1000-piece puzzle featuring a scenic mountain landscape.", price_cents: 1_699, stock: 75 },
    { name: "Building Blocks Deluxe Set 500 Pieces", description: "500-piece creative building block set compatible with major brands.", price_cents: 4_499, stock: 50 },
    { name: "Remote Control Racing Car", description: "High-speed RC car with full-function remote and rechargeable battery.", price_cents: 5_999, stock: 36 },
    { name: "Strategy Board Game: Settlers Quest", description: "An award-winning strategy board game for 2-4 players, ages 10 and up.", price_cents: 3_499, stock: 44 }
  ],
  "Office Supplies" => [
    { name: "Ergonomic Mesh Office Chair", description: "Breathable mesh office chair with adjustable lumbar support and armrests.", price_cents: 15_999, stock: 20 },
    { name: "Wireless Keyboard and Mouse Combo", description: "Slim wireless keyboard and mouse set with quiet-click keys.", price_cents: 4_499, stock: 68 },
    { name: "Adjustable Laptop Stand", description: "Aluminum laptop stand with adjustable height and angle for better posture.", price_cents: 2_999, stock: 92 },
    { name: "Premium Leather Notebook Journal", description: "A5 leather-bound journal with 200 pages of thick, lined paper.", price_cents: 1_999, stock: 105 }
  ]
}.freeze

CATEGORIES_WITH_PRODUCTS.each do |category_name, products|
  category = Category.find_or_create_by!(slug: category_name.parameterize) do |c|
    c.name = category_name
  end

  products.each do |product_attrs|
    product = Product.find_or_create_by!(name: product_attrs[:name]) do |new_product|
      new_product.description = product_attrs[:description]
      new_product.price_cents = product_attrs[:price_cents]
      new_product.stock = product_attrs[:stock]
      new_product.category = category
    end
    # Always refresh the placeholder image, so re-seeding an existing database
    # (e.g. after this generator changes) replaces any old image_url too.
    product.update!(image_url: placeholder_image_data_uri(product.name, category))
  end
end

puts "Seeded #{Category.count} categories and #{Product.count} products."

demo_user = User.find_or_create_by!(email: "demo@example.com") do |user|
  user.name = "Demo User"
  user.password = "password123"
  user.password_confirmation = "password123"
end

Cart.find_or_create_by!(user: demo_user)

sample_order_lines = [
  { product: Product.find_by!(name: "Wireless Noise-Cancelling Headphones"), quantity: 1 },
  { product: Product.find_by!(name: "Portable Bluetooth Speaker"), quantity: 1 },
  { product: Product.find_by!(name: "Insulated Stainless Steel Water Bottle 32oz"), quantity: 2 }
]
sample_order_total_cents = sample_order_lines.sum { |line| line[:product].price_cents * line[:quantity] }

sample_order = Order.find_or_create_by!(user: demo_user, status: :paid) do |order|
  order.total_cents = sample_order_total_cents
  order.shipping_name = "Demo User"
  order.shipping_address_line1 = "123 Main St"
  order.shipping_city = "Springfield"
  order.shipping_state = "IL"
  order.shipping_zip = "62704"
end

sample_order_lines.each do |line|
  OrderItem.find_or_create_by!(order: sample_order, product: line[:product]) do |order_item|
    order_item.quantity = line[:quantity]
    order_item.price_cents = line[:product].price_cents
  end
end

puts "Seeded demo user (demo@example.com / password123) with an empty cart and #{demo_user.orders.count} order(s)."
