# This file seeds a realistic catalog so the app doesn't look empty on first run.
# Safe to run repeatedly: everything is looked up with find_or_create_by!.
#
# Products have no stored image of any kind, and the app shows no photos:
# ProductsHelper#product_image_tag renders a designed tile per product (a tint
# of the category colour with the category icon). The catalog has no real
# product photos, and a stock photo of a different item would be a fake
# signal (docs/DESIGN.md).

CATEGORIES_WITH_PRODUCTS = {
  "Electronics" => [
    { name: "Wireless Noise-Cancelling Headphones", description: "Over-ear Bluetooth headphones with active noise cancellation and 30-hour battery life.", price_cents: 19_999, stock: 48 },
    { name: "4K Ultra HD Smart TV 55-inch", description: "55-inch 4K smart TV with HDR support and built-in streaming apps.", price_cents: 54_999, stock: 15 },
    { name: "Portable Bluetooth Speaker", description: "Compact waterproof speaker with 12 hours of playtime and deep bass.", price_cents: 5_999, stock: 76 },
    { name: "USB-C Fast Charging Power Bank 20000mAh", description: "High-capacity power bank with USB-C PD fast charging for phones and tablets.", price_cents: 3_999, stock: 102 },
    { name: "Mechanical Gaming Keyboard RGB Backlit", description: "Full-size mechanical keyboard with hot-swappable switches and customizable RGB lighting.", price_cents: 8_999, stock: 34 },
    { name: "Wireless Earbuds with Charging Case", description: "True wireless earbuds with active noise cancellation and 24-hour battery life with the case.", price_cents: 12_999, stock: 6 },
    { name: "27-inch QHD Gaming Monitor 144Hz", description: "27-inch curved gaming monitor with a 144Hz refresh rate and 1ms response time.", price_cents: 32_999, stock: 14 },
    { name: "Smartwatch with Heart Rate Monitor", description: "Fitness smartwatch with continuous heart rate tracking, GPS, and 7-day battery life.", price_cents: 17_999, stock: 42 },
    { name: "Compact Instant Camera", description: "Instant film camera with automatic exposure and a built-in flash for on-the-spot prints.", price_cents: 6_999, stock: 27 },
    { name: "Portable SSD 1TB USB-C", description: "Rugged 1TB external solid-state drive with USB-C and transfer speeds up to 1050MB/s.", price_cents: 9_999, stock: 58 },
    { name: "Smart Video Doorbell with Night Vision", description: "Wi-Fi video doorbell with 1080p HD, two-way audio, and infrared night vision.", price_cents: 8_999, stock: 5 },
    { name: "Bluetooth Car FM Transmitter", description: "Bluetooth FM transmitter with dual USB charging ports and hands-free calling for any car.", price_cents: 1_999, stock: 88 },
    { name: "Wireless Charging Pad 15W", description: "Fast wireless charging pad compatible with all Qi-enabled phones and earbuds.", price_cents: 2_499, stock: 130 },
    { name: "Mini Projector for Home Theater", description: "Portable LED projector with 1080p support, built-in speakers, and an HDMI input.", price_cents: 14_999, stock: 19 },
    { name: "Action Camera 4K Waterproof", description: "4K waterproof action camera with image stabilization and mounting accessories.", price_cents: 11_999, stock: 23 }
  ],
  "Home & Kitchen" => [
    { name: "Stainless Steel French Press Coffee Maker", description: "34oz French press with double-wall stainless steel construction for better heat retention.", price_cents: 3_499, stock: 60 },
    { name: "Non-Stick 12-Piece Cookware Set", description: "Complete non-stick cookware set including pots, pans, and lids, dishwasher safe.", price_cents: 12_999, stock: 22 },
    { name: "Robot Vacuum Cleaner with Mapping", description: "Smart robot vacuum with room mapping, app control, and automatic recharging.", price_cents: 24_999, stock: 18 },
    { name: "Electric Stand Mixer 5.5 Quart", description: "5.5-quart stand mixer with 10 speeds and dough hook, whisk, and paddle attachments.", price_cents: 18_999, stock: 25 },
    { name: "Digital Air Fryer 6 Quart", description: "6-quart digital air fryer with 8 preset cooking programs and a nonstick basket.", price_cents: 8_999, stock: 45 },
    { name: "Ceramic Nonstick Frying Pan 10-inch", description: "10-inch ceramic-coated frying pan with a stay-cool handle, safe up to 500°F.", price_cents: 2_999, stock: 74 },
    { name: "Electric Kettle with Temperature Control", description: "1.7L electric kettle with precise temperature settings for tea, coffee, and pour-over.", price_cents: 4_999, stock: 52 },
    { name: "Digital Kitchen Scale with Timer", description: "Precision digital kitchen scale with a built-in timer and tare function, up to 11 lbs.", price_cents: 1_499, stock: 96 },
    { name: "Bamboo Cutting Board Set of 3", description: "Set of three organic bamboo cutting boards in graduated sizes with juice grooves.", price_cents: 3_299, stock: 60 },
    { name: "12-Cup Programmable Drip Coffee Maker", description: "Programmable drip coffee maker with a 12-cup glass carafe and auto shut-off.", price_cents: 5_499, stock: 38 },
    { name: "Ceramic Plant Pot Set with Drainage", description: "Set of three ceramic planters with drainage holes and bamboo trays, for indoor herbs and succulents.", price_cents: 2_799, stock: 7 },
    { name: "Memory Foam Bath Mat Set", description: "Ultra-absorbent memory foam bath mat set of two with a non-slip backing.", price_cents: 2_299, stock: 82 },
    { name: "Stainless Steel Knife Block Set 15-Piece", description: "15-piece kitchen knife set with a wooden block, including chef, bread, and paring knives.", price_cents: 6_999, stock: 4 },
    { name: "Blackout Curtains 2 Panels 84-inch", description: "Thermal insulated blackout curtain panels that block 99% of light, set of two.", price_cents: 3_499, stock: 66 },
    { name: "Scented Soy Candle 3-Wick", description: "3-wick soy wax candle with a 45-hour burn time in a reusable glass jar.", price_cents: 1_899, stock: 110 }
  ],
  "Books" => [
    { name: "The Midnight Library", description: "A novel about the choices that go into a life well lived.", price_cents: 1_499, stock: 90 },
    { name: "Atomic Habits", description: "An easy and proven way to build good habits and break bad ones.", price_cents: 1_699, stock: 120 },
    { name: "A Brief History of Time", description: "A landmark volume in science writing on the origins and fate of the universe.", price_cents: 1_299, stock: 55 },
    { name: "The Silent Patient", description: "A psychological thriller about a woman's act of violence against her husband.", price_cents: 1_399, stock: 70 },
    { name: "Educated: A Memoir", description: "A memoir about a woman who grows up in a survivalist family and pursues higher education.", price_cents: 1_599, stock: 68 },
    { name: "Where the Crawdads Sing", description: "A coming-of-age novel and murder mystery set in the marshes of North Carolina.", price_cents: 1_499, stock: 84 },
    { name: "Sapiens: A Brief History of Humankind", description: "A sweeping history of the human species from the Stone Age to the present.", price_cents: 1_799, stock: 47 },
    { name: "The Very Hungry Caterpillar", description: "A classic picture book following a caterpillar's journey to becoming a butterfly.", price_cents: 999, stock: 130 },
    { name: "Dune", description: "An epic science fiction novel set on the desert planet Arrakis.", price_cents: 1_699, stock: 59 },
    { name: "The Power of Now", description: "A guide to spiritual enlightenment through living fully in the present moment.", price_cents: 1_399, stock: 71 },
    { name: "Cookbook: Simple Weeknight Dinners", description: "A collection of 100 easy, family-friendly recipes for busy weeknights.", price_cents: 2_199, stock: 33 },
    { name: "The Hobbit", description: "A fantasy adventure following Bilbo Baggins on an unexpected journey.", price_cents: 1_299, stock: 92 },
    { name: "Quiet: The Power of Introverts", description: "An exploration of introversion in a world that can't stop talking.", price_cents: 1_599, stock: 8 }
  ],
  "Clothing" => [
    { name: "Men's Classic Fit Oxford Shirt", description: "Breathable cotton oxford shirt with a classic fit, available in multiple colors.", price_cents: 2_999, stock: 85 },
    { name: "Women's High-Waisted Yoga Leggings", description: "Squat-proof high-waisted leggings with four-way stretch fabric.", price_cents: 2_499, stock: 110 },
    { name: "Unisex Fleece Pullover Hoodie", description: "Soft fleece hoodie with a kangaroo pocket and adjustable drawstring hood.", price_cents: 3_999, stock: 95 },
    { name: "Waterproof Hiking Jacket", description: "Lightweight waterproof shell jacket built for wet-weather hiking.", price_cents: 8_999, stock: 30 },
    { name: "Men's Slim Fit Chino Pants", description: "Cotton-blend slim fit chinos with a flat front, available in multiple colors.", price_cents: 3_499, stock: 78 },
    { name: "Women's Wrap Midi Dress", description: "Flowy wrap midi dress with a V-neckline and tie waist, perfect for warm weather.", price_cents: 4_299, stock: 41 },
    { name: "Unisex Cotton Crew Socks 6-Pack", description: "Six-pack of breathable cotton crew socks with cushioned soles.", price_cents: 1_499, stock: 160 },
    { name: "Men's Merino Wool Sweater", description: "Soft merino wool crewneck sweater, machine washable and naturally odor-resistant.", price_cents: 5_999, stock: 6 },
    { name: "Women's Denim Jacket", description: "Classic cropped denim jacket with button closures and chest pockets.", price_cents: 4_999, stock: 53 },
    { name: "Kids' Rain Boots Waterproof", description: "Waterproof rubber rain boots for kids with a non-slip tread and easy pull-on tabs.", price_cents: 2_499, stock: 5 },
    { name: "Men's Running Shorts with Liner", description: "Lightweight running shorts with a built-in liner and a zip pocket for keys.", price_cents: 2_799, stock: 87 },
    { name: "Women's Silk Scarf", description: "100% silk scarf with a hand-rolled edge, versatile enough for hair, neck, or bag.", price_cents: 2_999, stock: 24 },
    { name: "Unisex Baseball Cap Adjustable", description: "Cotton twill baseball cap with an adjustable strap back and curved brim.", price_cents: 1_799, stock: 115 },
    { name: "Men's Leather Belt Reversible", description: "Reversible genuine leather belt with a rotating buckle for two looks in one.", price_cents: 2_999, stock: 69 }
  ],
  "Sports & Outdoors" => [
    { name: "Adjustable Dumbbell Set 5-50 lbs", description: "Space-saving adjustable dumbbells that replace 15 sets of weights.", price_cents: 29_999, stock: 12 },
    { name: "2-Person Camping Tent", description: "Lightweight 3-season tent with easy setup and full rainfly coverage.", price_cents: 11_999, stock: 28 },
    { name: "Yoga Mat with Carrying Strap", description: "Extra-thick non-slip yoga mat with a built-in carrying strap.", price_cents: 2_299, stock: 130 },
    { name: "Insulated Stainless Steel Water Bottle 32oz", description: "Double-wall vacuum insulated bottle that keeps drinks cold for 24 hours.", price_cents: 1_999, stock: 150 },
    { name: "Running Shoes Lightweight Breathable", description: "Lightweight running shoes with breathable mesh uppers and responsive cushioning.", price_cents: 7_999, stock: 44 },
    { name: "Foldable Camping Chair with Cup Holder", description: "Portable folding camping chair with a built-in cup holder and carry bag.", price_cents: 3_499, stock: 3 },
    { name: "Resistance Bands Set of 5", description: "Set of five resistance bands in varying tension levels with a carrying pouch.", price_cents: 1_999, stock: 145 },
    { name: "Hydration Backpack 2L", description: "Lightweight hydration backpack with a 2-liter bladder, ideal for hiking and cycling.", price_cents: 4_499, stock: 31 },
    { name: "Inflatable Stand-Up Paddleboard", description: "10.6-foot inflatable paddleboard with a pump, paddle, and backpack included.", price_cents: 34_999, stock: 9 },
    { name: "Trekking Poles Collapsible Pair", description: "Lightweight aluminum trekking poles with adjustable height and cork grips, sold as a pair.", price_cents: 3_999, stock: 56 },
    { name: "Cycling Helmet with LED Light", description: "Ventilated cycling helmet with an integrated rear LED safety light.", price_cents: 4_999, stock: 26 },
    { name: "Fishing Rod and Reel Combo", description: "6-foot fishing rod and spinning reel combo, ready to cast out of the box.", price_cents: 5_499, stock: 17 },
    { name: "Basketball Official Size 7", description: "Official size composite leather basketball for indoor and outdoor courts.", price_cents: 2_999, stock: 63 }
  ],
  "Beauty & Personal Care" => [
    { name: "Vitamin C Brightening Serum", description: "Antioxidant-rich facial serum that brightens skin and reduces dark spots.", price_cents: 2_499, stock: 88 },
    { name: "Electric Rechargeable Toothbrush", description: "Sonic toothbrush with 5 cleaning modes and a 2-week battery life.", price_cents: 4_999, stock: 65 },
    { name: "Ceramic Hair Straightener", description: "Fast-heating ceramic plates with adjustable temperature settings.", price_cents: 3_499, stock: 40 },
    { name: "Nourishing Shea Butter Body Lotion", description: "Rich body lotion made with shea butter for 24-hour moisture.", price_cents: 1_299, stock: 140 },
    { name: "Hyaluronic Acid Moisturizing Cream", description: "Lightweight daily moisturizer with hyaluronic acid for 24-hour hydration.", price_cents: 2_199, stock: 97 },
    { name: "Electric Nail File and Buffer Kit", description: "Cordless electric nail file and buffer kit with interchangeable heads for manicures and pedicures.", price_cents: 2_999, stock: 4 },
    { name: "Bamboo Charcoal Face Mask 10-Pack", description: "Purifying bamboo charcoal sheet masks that draw out impurities, pack of 10.", price_cents: 1_499, stock: 120 },
    { name: "Men's Beard Grooming Kit", description: "Complete beard grooming kit with oil, balm, comb, and scissors in a gift box.", price_cents: 3_499, stock: 39 },
    { name: "Sulfate-Free Shampoo and Conditioner Set", description: "Sulfate-free shampoo and conditioner duo for color-treated hair.", price_cents: 2_699, stock: 74 },
    { name: "Rose Gold Hair Dryer with Diffuser", description: "Ionic hair dryer with a diffuser attachment and three heat settings.", price_cents: 4_499, stock: 28 },
    { name: "Makeup Brush Set 12-Piece", description: "12-piece synthetic makeup brush set with a travel case.", price_cents: 1_999, stock: 6 },
    { name: "Essential Oil Diffuser with LED Light", description: "Ultrasonic essential oil diffuser with a color-changing LED light and auto shut-off.", price_cents: 2_999, stock: 55 },
    { name: "Electric Facial Cleansing Brush", description: "Waterproof silicone facial cleansing brush with adjustable vibration intensity.", price_cents: 2_499, stock: 81 },
    { name: "Sunscreen SPF 50 Broad Spectrum", description: "Lightweight broad-spectrum SPF 50 sunscreen that absorbs quickly without residue.", price_cents: 1_799, stock: 145 }
  ],
  "Toys & Games" => [
    { name: "1000-Piece Jigsaw Puzzle: Mountain Landscape", description: "A challenging 1000-piece puzzle featuring a scenic mountain landscape.", price_cents: 1_699, stock: 75 },
    { name: "Building Blocks Deluxe Set 500 Pieces", description: "500-piece creative building block set compatible with major brands.", price_cents: 4_499, stock: 50 },
    { name: "Remote Control Racing Car", description: "High-speed RC car with full-function remote and rechargeable battery.", price_cents: 5_999, stock: 36 },
    { name: "Strategy Board Game: Settlers Quest", description: "An award-winning strategy board game for 2-4 players, ages 10 and up.", price_cents: 3_499, stock: 44 },
    { name: "Wooden Building Blocks Set 100-Piece", description: "100-piece natural wood building block set for open-ended creative play.", price_cents: 3_499, stock: 48 },
    { name: "Plush Teddy Bear 18-inch", description: "Soft 18-inch plush teddy bear, machine washable and safe for all ages.", price_cents: 1_999, stock: 92 },
    { name: "Card Game: Classic Family Trivia", description: "Family trivia card game with 500 questions spanning six categories.", price_cents: 1_699, stock: 63 },
    { name: "Kids' Art Easel with Storage", description: "Double-sided wooden art easel with a chalkboard, whiteboard, and paper roll storage.", price_cents: 6_499, stock: 5 },
    { name: "Building Bricks Space Station Set", description: "450-piece interlocking brick space station set with three mini-figures.", price_cents: 5_999, stock: 29 },
    { name: "Remote Control Drone with Camera", description: "Beginner-friendly RC drone with an HD camera and one-touch takeoff and landing.", price_cents: 8_999, stock: 14 },
    { name: "Wooden Train Set 60-Piece", description: "60-piece wooden train track set compatible with major wooden railway brands.", price_cents: 4_999, stock: 37 },
    { name: "Water Balloon Set 500-Count", description: "Self-sealing water balloons, 500-count, fills in under a minute with the included nozzle.", price_cents: 1_299, stock: 210 },
    { name: "Kids' Science Experiment Kit", description: "STEM science kit with 20 hands-on experiments and a full instruction guide.", price_cents: 2_999, stock: 42 }
  ],
  "Office Supplies" => [
    { name: "Ergonomic Mesh Office Chair", description: "Breathable mesh office chair with adjustable lumbar support and armrests.", price_cents: 15_999, stock: 20 },
    { name: "Wireless Keyboard and Mouse Combo", description: "Slim wireless keyboard and mouse set with quiet-click keys.", price_cents: 4_499, stock: 68 },
    { name: "Adjustable Laptop Stand", description: "Aluminum laptop stand with adjustable height and angle for better posture.", price_cents: 2_999, stock: 92 },
    { name: "Premium Leather Notebook Journal", description: "A5 leather-bound journal with 200 pages of thick, lined paper.", price_cents: 1_999, stock: 105 },
    { name: "Standing Desk Converter", description: "Adjustable standing desk converter that sits on top of any desk for sit-stand work.", price_cents: 15_999, stock: 3 },
    { name: "Wireless Mouse Ergonomic", description: "Ergonomic wireless mouse with a vertical grip to reduce wrist strain.", price_cents: 2_999, stock: 88 },
    { name: "Desk Organizer with Drawers", description: "Multi-compartment desk organizer with two drawers for pens, sticky notes, and paperclips.", price_cents: 2_499, stock: 54 },
    { name: "Whiteboard Dry Erase 36x24", description: "36x24-inch magnetic dry erase whiteboard with an aluminum frame and marker tray.", price_cents: 3_999, stock: 22 },
    { name: "Paper Shredder Cross-Cut", description: "8-sheet cross-cut paper shredder with a pullout wastebasket, handles staples and clips.", price_cents: 5_499, stock: 16 },
    { name: "LED Desk Lamp with USB Charging Port", description: "Dimmable LED desk lamp with a built-in USB charging port and adjustable arm.", price_cents: 3_499, stock: 67 },
    { name: "Sticky Notes Assorted Colors 12-Pack", description: "12-pack of sticky notes in assorted colors and sizes for organizing tasks.", price_cents: 899, stock: 190 },
    { name: "Bluetooth Label Maker", description: "Portable Bluetooth label maker that prints from a smartphone app, no ink required.", price_cents: 4_999, stock: 8 },
    { name: "Executive Ballpoint Pen Set", description: "Set of two executive ballpoint pens with a gift box, smooth-writing refillable ink.", price_cents: 2_199, stock: 76 }
  ]
}.freeze

CATEGORIES_WITH_PRODUCTS.each do |category_name, products|
  category = Category.find_or_create_by!(slug: category_name.parameterize) do |c|
    c.name = category_name
  end

  products.each do |product_attrs|
    Product.find_or_create_by!(name: product_attrs[:name]) do |new_product|
      new_product.description = product_attrs[:description]
      new_product.price_cents = product_attrs[:price_cents]
      new_product.stock = product_attrs[:stock]
      new_product.category = category
    end
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
