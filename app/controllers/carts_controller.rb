class CartsController < ApplicationController
  before_action :require_login

  def show
    @cart = current_user.ensure_cart!
    authorize @cart
    @cart_items = @cart.cart_items.includes(product: :category).order(:created_at)
    @saved_items = current_user.wishlist_items.includes(product: :category).order(created_at: :desc)
  end
end
