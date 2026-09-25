class ProductsController < ApplicationController
  include Pagy::Method

  PER_PAGE = 24

  def index
    @categories = Category.order(:name)
    @selected_category = Category.find_by(slug: params[:category]) if params[:category].present?
    @query = params[:query].to_s.strip

    scope = Product.includes(:category)
    scope = scope.where(category: @selected_category) if @selected_category
    scope = @query.present? ? scope.search_full_text(@query) : scope.order(:name)

    if params[:page].present? && !params[:page].to_s.match?(/\A[1-9]\d*\z/)
      redirect_to products_path(category: params[:category].presence, query: params[:query].presence) and return
    end

    @pagy, @products = pagy(scope, limit: PER_PAGE)

    redirect_to_last_page and return if @pagy.page > @pagy.last
  end

  def show
    @product = Product.includes(:category).find(params[:id])
  end

  private

  # A numeric but out-of-range ?page= (e.g. past the last page) doesn't raise
  # in this Pagy version -- it just returns an empty page -- so redirect to
  # the real last page instead of showing a confusing empty result set.
  def redirect_to_last_page
    redirect_to products_path(category: params[:category].presence, query: params[:query].presence, page: @pagy.last)
  end
end
