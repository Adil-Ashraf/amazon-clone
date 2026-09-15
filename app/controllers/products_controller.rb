class ProductsController < ApplicationController
  def index
    @categories = Category.order(:name)
    @selected_category = Category.find_by(slug: params[:category]) if params[:category].present?
    @query = params[:query].to_s.strip

    @products = Product.includes(:category)
    @products = @products.where(category: @selected_category) if @selected_category
    @products = @query.present? ? @products.search_full_text(@query) : @products.order(:name)
  end

  def show
    @product = Product.includes(:category).find(params[:id])
  end
end
