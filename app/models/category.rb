class Category < ApplicationRecord
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  # Which glyph (see CategoriesHelper::ICON_PATHS) represents this category,
  # used for both the sidebar icon and the generated product placeholder
  # images -- kept as data here, rendered as markup in the helper.
  ICON_KEYS = {
    "electronics" => :chip,
    "home-kitchen" => :house,
    "books" => :book,
    "clothing" => :shirt,
    "sports-outdoors" => :dumbbell,
    "beauty-personal-care" => :droplet,
    "toys-games" => :dice,
    "office-supplies" => :briefcase
  }.freeze

  COLOR_HEXES = {
    "electronics" => "#2563eb",
    "home-kitchen" => "#d97706",
    "books" => "#9333ea",
    "clothing" => "#db2777",
    "sports-outdoors" => "#16a34a",
    "beauty-personal-care" => "#e11d48",
    "toys-games" => "#ea580c",
    "office-supplies" => "#475569"
  }.freeze

  DEFAULT_ICON_KEY = :tag

  # Hand-picked, verified-free Unsplash photos per category, each hotlinked by
  # its permanent photo ID rather than a keyword search -- so the same set of
  # images loads every time instead of whatever a query happens to match
  # today. Every product in a category cycles through that category's photos
  # (see #representative_image_url) rather than all sharing a single image,
  # so browsing a category doesn't look like the same product repeated.
  # Falls back to the generated color tile (see ProductsHelper#
  # product_image_tag) if a URL ever fails to load.
  IMAGE_URLS = {
    "electronics" => %w[
      1615663245857-ac93bb7c39e7
      1652819804299-eea887780ca7
      1578319439584-104c94d37305
      1606220588913-b3aacb4d2f46
      1582056615449-5dcb2332b3b2
      1445620466293-d6316372ab59
      1488485339565-566d63f7dbb7
      1679153369902-50687ca31379
    ],
    "home-kitchen" => %w[
      1556912173-46c336c7fd55
      1556910602-38f53e68e15d
      1586969593928-1c87c1f9c2ef
      1520981825232-ece5fae45120
      1738484708927-c1f45df0b56e
      1610821165540-80c084d50fd3
      1691403992101-a5d6f9dec356
      1708972789121-56f5e2731ea3
      1549127024-5f213d45604a
    ],
    "books" => %w[
      1660606422342-2ce59709bb14
      1610116306796-6fea9f4fae38
      1550399105-c4db5fb85c18
      1543002588-bfa74002ed7e
      1570676765227-b25aa08d9752
      1520467795206-62e33627e6ce
      1602396111763-06556dd0063a
      1607473129070-af6b54fd784b
    ],
    "clothing" => %w[
      1629426958003-35a5583b2977
      1641642231157-0849081598a2
      1560060141-7b9018741ced
      1760013531865-89ff324f83a6
      1668069226492-508742b03147
      1533867617858-e7b97e060509
      1449505278894-297fdb3edbc1
      1737043818804-5b2654929779
      1737044252968-aa44f07c339e
    ],
    "sports-outdoors" => %w[
      1576678927484-cc907957088c
      1763004871583-4183d64096b1
      1767605545968-a102fc151b08
      1780589093361-ba2561f20c9b
      1603077492340-e6e62b2a688b
      1562771242-a02d9090c90c
      1544033527-b192daee1f5b
      1623789658209-00c06091e6eb
      1598410924570-6e37b6c54fe6
    ],
    "beauty-personal-care" => %w[
      1596462502278-27bfdc403348
      1527986654082-0b5b3fef2632
      1574421233376-06f2ccf017f7
      1684248655527-46bee8e79029
      1619695663382-ba3916f2d79f
      1620914020016-7ebe3cb03329
      1663089889839-486fa57d3411
      1772915022472-ffc1df2d6051
    ],
    "toys-games" => %w[
      1756405520788-9a0e2c4bacf7
      1703581698778-2224c729135b
      1568828668638-b1b4014d91a2
      1714618888538-8d15a9228236
      1638802538115-041e14d28d6a
      1575364289437-fb1479d52732
      1494059980473-813e73ee784b
      1704027689040-26184f878a78
    ],
    "office-supplies" => %w[
      1764818958942-f104ba6f8358
      1617177435486-ce12dc2fd983
      1617177435596-1c9e30d6d608
      1512278753435-c834ff8a597a
      1609881532802-493ca789f868
      1568149537277-4daf47b8a6dd
      1527049174080-a87281343ddf
      1571254120989-7a3c07c50c98
      1551893476-7d5023fef9dc
    ]
  }.freeze

  def icon_key
    ICON_KEYS.fetch(slug, DEFAULT_ICON_KEY)
  end

  def color_hex
    COLOR_HEXES.fetch(slug, "#64748b")
  end

  # Deterministically picks one of this category's photos for the given
  # product id, so the same product always shows the same photo but
  # different products in the same category don't all show the same one.
  def representative_image_url(seed)
    photo_ids = IMAGE_URLS.fetch(slug, [])
    return nil if photo_ids.empty?

    "https://images.unsplash.com/photo-#{photo_ids[seed % photo_ids.length]}?w=1200&q=80&auto=format&fit=crop"
  end
end
