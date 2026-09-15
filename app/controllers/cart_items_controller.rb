class CartItemsController < ApplicationController
  before_action :require_login
  before_action :set_cart

  def create
    product = Product.find(params[:product_id])
    quantity = params[:quantity].presence&.to_i || 1

    begin
      Carts::CartService.new(@cart).add_item(product: product, quantity: quantity)
      @status_message = "Added to cart."
      @status_class = "text-green-700"
    rescue Carts::CartService::InsufficientStockError => e
      @status_message = e.message
      @status_class = "text-red-600"
    end

    load_cart_items
  end

  def update
    cart_item = @cart.cart_items.find(params[:id])

    begin
      Carts::CartService.new(@cart).update_quantity(cart_item: cart_item, quantity: params[:quantity].to_i)
    rescue Carts::CartService::InsufficientStockError => e
      @cart_flash_message = e.message
      @cart_flash_class = "bg-red-100 text-red-800"
    end

    load_cart_items
  end

  def destroy
    cart_item = @cart.cart_items.find(params[:id])
    Carts::CartService.new(@cart).remove_item(cart_item: cart_item)

    load_cart_items
  end

  private

  def set_cart
    @cart = current_user.cart
    authorize @cart, :update?
  end

  def load_cart_items
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
  end
end
