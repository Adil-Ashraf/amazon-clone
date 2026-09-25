class Category < ApplicationRecord
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  # Which glyph (see CategoriesHelper::ICON_PATHS) represents this category,
  # used for both the category menus and the designed product tiles
  # (ProductsHelper#product_image_tag) -- kept as data here, rendered as
  # markup in the helper.
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

  DEFAULT_ICON_KEY = :tag

  def icon_key
    ICON_KEYS.fetch(slug, DEFAULT_ICON_KEY)
  end
end
