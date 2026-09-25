# Storefront data on top of the catalog in db/seeds.rb: markdowns, reviews
# and orders in every status. Loaded at the end of db/seeds.rb and safe to
# re-run. Everything here goes through the same tables the app writes to;
# the pages read it back with ordinary queries.

# --- Markdowns -------------------------------------------------------------
# compare_at_price_cents is the regular price a product is marked down from.
# Rounded up to a .99 price, the way a store would set it.
MARKDOWN_FACTORS = [ 1.2, 1.25, 1.3, 1.4, 1.5 ].freeze
ON_SALE = [
  "Wireless Noise-Cancelling Headphones", "Portable Bluetooth Speaker", "Smartwatch with Heart Rate Monitor",
  "Mechanical Gaming Keyboard RGB Backlit", "Mini Projector for Home Theater", "Action Camera 4K Waterproof",
  "Digital Air Fryer 6 Quart", "Robot Vacuum Cleaner with Mapping", "Electric Kettle with Temperature Control",
  "Non-Stick 12-Piece Cookware Set", "Scented Soy Candle 3-Wick",
  "Waterproof Hiking Jacket", "Men's Merino Wool Sweater", "Women's Denim Jacket", "Women's Wrap Midi Dress",
  "Unisex Fleece Pullover Hoodie", "Running Shoes Lightweight Breathable", "2-Person Camping Tent",
  "Rose Gold Hair Dryer with Diffuser", "Vitamin C Brightening Serum", "Remote Control Drone with Camera",
  "Ergonomic Mesh Office Chair", "Sapiens: A Brief History of Humankind"
].freeze

ON_SALE.each_with_index do |name, index|
  product = Product.find_by(name: name)
  next unless product

  factor = MARKDOWN_FACTORS[index % MARKDOWN_FACTORS.size]
  product.update!(compare_at_price_cents: ((product.price_cents * factor) / 100.0).ceil * 100 - 1)
end

puts "Marked down #{Product.on_sale.count} products."

# --- Reviewers and their orders ----------------------------------------------
# A review can only come from someone who bought the product
# (Reviews::CreateService), so every seeded reviewer gets a delivered order
# containing what they review.
REVIEWERS = [
  "Maya Robinson", "Daniel Okafor", "Priya Shah", "Tom Becker", "Lucia Fernández", "Sam Whitaker",
  "Hana Kim", "Marcus Lee", "Elena Petrova", "Jordan Blake", "Aisha Rahman", "Oliver Grant"
].freeze

REVIEW_BODIES = {
  5 => [
    "Exactly as described and well made. It has become part of my daily routine.",
    "Arrived quickly and the quality is better than I expected for the price.",
    "I did a lot of comparing before buying this one and I'm glad I did. No complaints.",
    "Bought one for myself and ended up ordering a second as a gift.",
    "Simple, sturdy and it just works. Would buy again without thinking."
  ],
  4 => [
    "Really good overall. Packaging could have been lighter, but the product itself is great.",
    "Does what it says. Took a day to get used to, now I use it all the time.",
    "Solid quality for the money. Knocked off a star only because the instructions were thin.",
    "Happy with it. Looks nicer in person than in the photos."
  ],
  3 => [
    "It's fine. Works as expected, but nothing about it stands out.",
    "Decent, though a little smaller than I pictured. Check the dimensions first."
  ],
  2 => [
    "Not for me. It works, but the finish felt cheaper than the price suggests."
  ]
}.freeze

random = Random.new(2026)
reviewed_products = Product.order(:id).select { |product| random.rand < 0.7 }

reviewers = REVIEWERS.each_with_index.map do |name, index|
  User.find_or_create_by!(email: "reviewer#{index + 1}@example.com") do |user|
    user.name = name
    user.password = SecureRandom.base58(24)
  end
end

reviewers.each_with_index do |reviewer, reviewer_index|
  products = reviewed_products.select { |product| (product.id + reviewer_index) % 3 != 0 }.first(40)
  next if products.empty? || reviewer.orders.exists?

  placed_at = random.rand(20..120).days.ago
  lines = products.map { |product| { product: product, quantity: 1 + random.rand(2) } }
  subtotal = lines.sum { |line| line[:product].price_cents * line[:quantity] }

  order = reviewer.orders.create!(
    status: :delivered, shipping_cents: Order.shipping_cents_for(subtotal),
    total_cents: subtotal + Order.shipping_cents_for(subtotal),
    shipping_name: reviewer.name, shipping_address_line1: "#{10 + reviewer_index} Market Street",
    shipping_city: "Portland", shipping_state: "OR", shipping_zip: "97205",
    created_at: placed_at, updated_at: placed_at
  )
  lines.each do |line|
    order.order_items.create!(product: line[:product], quantity: line[:quantity], price_cents: line[:product].price_cents,
      created_at: placed_at, updated_at: placed_at)
  end

  products.each do |product|
    rating = [ 5, 5, 5, 4, 4, 4, 5, 3, 4, 2 ][random.rand(10)]
    reviewed_at = placed_at + random.rand(3..15).days
    product.reviews.create!(user: reviewer, rating: rating, body: REVIEW_BODIES[rating].sample(random: random),
      created_at: reviewed_at, updated_at: reviewed_at)
  end
end

# Refresh the aggregates Reviews::CreateService keeps in step.
Product.find_each do |product|
  average = product.reviews.average(:rating)
  product.update_columns(reviews_count: product.reviews.count, rating_average: average ? average.round(1) : 0)
end

puts "Seeded #{reviewers.size} reviewers, #{Review.count} reviews on #{Product.where('reviews_count > 0').count} products."

# --- Demo account history --------------------------------------------------
demo_user = User.find_by!(email: "demo@example.com")

DEMO_ORDERS = [
  { status: :delivered, days_ago: 45, lines: [ [ "Stainless Steel French Press Coffee Maker", 1 ], [ "Atomic Habits", 1 ] ] },
  { status: :out_for_delivery, days_ago: 3, lines: [ [ "Yoga Mat with Carrying Strap", 1 ], [ "Resistance Bands Set of 5", 1 ] ] },
  { status: :shipped, days_ago: 5, lines: [ [ "Wireless Keyboard and Mouse Combo", 1 ] ] },
  { status: :cancelled, days_ago: 30, lines: [ [ "Scented Soy Candle 3-Wick", 2 ] ] }
].freeze

DEMO_ORDERS.each do |spec|
  next if demo_user.orders.exists?(status: spec[:status])

  lines = spec[:lines].map { |name, quantity| [ Product.find_by!(name: name), quantity ] }
  subtotal = lines.sum { |product, quantity| product.price_cents * quantity }
  placed_at = spec[:days_ago].days.ago

  order = demo_user.orders.create!(
    status: spec[:status], shipping_cents: Order.shipping_cents_for(subtotal),
    total_cents: subtotal + Order.shipping_cents_for(subtotal),
    shipping_name: "Demo User", shipping_address_line1: "123 Main St", shipping_city: "Springfield",
    shipping_state: "IL", shipping_zip: "62704", created_at: placed_at, updated_at: placed_at
  )
  lines.each do |product, quantity|
    order.order_items.create!(product: product, quantity: quantity, price_cents: product.price_cents)
  end
end

[ "Robot Vacuum Cleaner with Mapping", "Waterproof Hiking Jacket", "Compact Instant Camera" ].each do |name|
  demo_user.wishlist_items.find_or_create_by!(product: Product.find_by!(name: name))
end

puts "Demo user has #{demo_user.orders.count} orders and #{demo_user.wishlist_items.count} wishlist items."
