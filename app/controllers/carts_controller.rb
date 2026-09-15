class CartsController < ApplicationController
  before_action :require_login

  def show
    @cart = current_user.cart
    authorize @cart
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
  end
end
