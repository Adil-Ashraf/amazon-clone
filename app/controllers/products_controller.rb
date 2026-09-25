class ProductsController < ApplicationController
  include Pagy::Method

  PER_PAGE = 24

  # Whitelisted sort keys -> ORDER BY. params[:sort] is only ever used as a
  # lookup key here, never interpolated into SQL. "relevance" keeps
  # pg_search's rank order, so it only applies when there is a query.
  SORTS = {
    "relevance" => nil,
    "name" => { name: :asc },
    "price_asc" => { price_cents: :asc },
    "price_desc" => { price_cents: :desc },
    "newest" => { created_at: :desc }
  }.freeze

  def index
    @categories = Category.order(:name)
    @selected_category = Category.find_by(slug: params[:category]) if params[:category].present?
    @query = params[:query].to_s.strip
    @sort = requested_sort || default_sort
    # Only carried through links and redirects when the shopper picked it,
    # so default URLs stay clean.
    @sort_param = @sort unless @sort == default_sort

    if params[:page].present? && !params[:page].to_s.match?(/\A[1-9]\d*\z/)
      redirect_to listing_path and return
    end

    @pagy, @products = pagy(listing_scope, limit: PER_PAGE)

    redirect_to_last_page and return if @pagy.page > @pagy.last

    @bag_quantities = bag_quantities_for(@products)
  end

  def show
    @product = Product.includes(:category).find(params[:id])
  end

  private

  def listing_scope
    scope = Product.includes(:category)
    scope = scope.where(category: @selected_category) if @selected_category
    scope = scope.search_full_text(@query) if @query.present?

    order = SORTS.fetch(@sort)
    order ? scope.reorder(order).order(:id) : scope
  end

  def requested_sort
    sort = params[:sort].to_s
    return unless SORTS.key?(sort)
    return if sort == "relevance" && @query.blank?

    sort
  end

  def default_sort
    @query.present? ? "relevance" : "name"
  end

  def bag_quantities_for(products)
    cart = current_user&.cart
    return {} unless cart

    cart.cart_items.where(product_id: products.map(&:id)).pluck(:product_id, :quantity).to_h
  end

  def listing_path(page: nil)
    products_path(category: params[:category].presence, query: params[:query].presence, sort: @sort_param, page: page)
  end

  # A numeric but out-of-range ?page= (e.g. past the last page) doesn't raise
  # in this Pagy version -- it just returns an empty page -- so redirect to
  # the real last page instead of showing a confusing empty result set.
  def redirect_to_last_page
    redirect_to listing_path(page: @pagy.last)
  end
end
