class ProductsController < ApplicationController
  include Pagy::Method

  PER_PAGE = 24

  # Whitelisted sort keys -> ORDER BY. params[:sort] is only ever used as a
  # lookup key here, never interpolated into SQL. "relevance" keeps
  # pg_search's rank order, so it only applies when there is a query.
  SORTS = {
    "relevance" => nil,
    "featured" => { reviews_count: :desc, rating_average: :desc },
    "price_asc" => { price_cents: :asc },
    "price_desc" => { price_cents: :desc },
    "newest" => { created_at: :desc },
    "rating" => { rating_average: :desc, reviews_count: :desc }
  }.freeze

  RATING_FILTERS = [ 4, 3 ].freeze
  VIEWS = %w[grid list].freeze

  def index
    @categories = nav_categories.sort_by(&:name)
    @selected_category = Category.find_by(slug: params[:category]) if params[:category].present?
    @query = params[:query].to_s.strip
    @sort = requested_sort || default_sort
    @filters = requested_filters
    @view = VIEWS.include?(params[:view]) ? params[:view] : "grid"
    # Everything that shapes the listing, minus defaults, for building links
    # that change one thing and keep the rest.
    @listing_params = {
      category: @selected_category&.slug, query: @query.presence,
      sort: (@sort unless @sort == default_sort), view: (@view unless @view == "grid"), **@filters
    }.compact

    if params[:page].present? && !params[:page].to_s.match?(/\A[1-9]\d*\z/)
      redirect_to listing_path and return
    end

    @pagy, @products = pagy(listing_scope, limit: PER_PAGE)

    redirect_to_last_page and return if @pagy.page > @pagy.last

    load_card_state(@products)
  end

  def show
    @product = Product.includes(:category).find(params[:id])
    @reviews = @product.reviews.includes(:user).order(created_at: :desc).limit(10)
    @rating_counts = @product.reviews.group(:rating).count
    @related = Product.includes(:category).where(category: @product.category)
      .where.not(id: @product.id).top_rated.limit(4).to_a
    @recently_viewed = recently_viewed_products(excluding: @product).first(4)
    @can_review = current_user.present? && current_user.purchased?(@product) &&
      !@product.reviews.exists?(user: current_user)

    load_card_state([ @product ] + @related + @recently_viewed)
    remember_viewed(@product)
  end

  private

  def listing_scope
    scope = Product.includes(:category)
    scope = scope.where(category: @selected_category) if @selected_category
    scope = scope.search_full_text(@query) if @query.present?
    scope = scope.where(price_cents: (@filters[:price_min] * 100)..) if @filters[:price_min]
    scope = scope.where(price_cents: ..(@filters[:price_max] * 100)) if @filters[:price_max]
    scope = scope.in_stock if @filters[:in_stock]
    scope = scope.on_sale if @filters[:deals]
    scope = scope.where(rating_average: @filters[:rating]..) if @filters[:rating]

    order = SORTS.fetch(@sort)
    order ? scope.reorder(order).order(:id) : scope
  end

  # Only filters the shopper actually set, as clean values, so they can be
  # passed straight back into URLs.
  def requested_filters
    {
      price_min: whole_dollars(params[:price_min]),
      price_max: whole_dollars(params[:price_max]),
      in_stock: params[:in_stock] == "1" || nil,
      deals: params[:deals] == "1" || nil,
      rating: RATING_FILTERS.find { |rating| rating.to_s == params[:rating] }
    }.compact
  end

  def whole_dollars(value)
    value.to_s.match?(/\A\d{1,6}\z/) ? value.to_i : nil
  end

  def requested_sort
    sort = params[:sort].to_s
    return unless SORTS.key?(sort)
    return if sort == "relevance" && @query.blank?

    sort
  end

  def default_sort
    @query.present? ? "relevance" : "featured"
  end

  def listing_path(page: nil)
    products_path(**@listing_params, category: params[:category].presence, page: page)
  end

  # A numeric but out-of-range ?page= (e.g. past the last page) doesn't raise
  # in this Pagy version -- it just returns an empty page -- so redirect to
  # the real last page instead of showing a confusing empty result set.
  def redirect_to_last_page
    redirect_to listing_path(page: @pagy.last)
  end
end
