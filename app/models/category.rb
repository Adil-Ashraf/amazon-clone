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

  def icon_key
    ICON_KEYS.fetch(slug, DEFAULT_ICON_KEY)
  end

  def color_hex
    COLOR_HEXES.fetch(slug, "#64748b")
  end
end
