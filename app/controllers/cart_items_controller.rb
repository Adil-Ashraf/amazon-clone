class CartItemsController < ApplicationController
  before_action :require_login
  before_action :set_cart

  def create
    @product = Product.find(params[:product_id])
    quantity = params[:quantity].presence&.to_i || 1

    begin
      Carts::CartService.new(@cart).add_item(product: @product, quantity: quantity)
      @status_message = "Added to your cart"
      @status_variant = :success
    rescue Carts::CartService::InsufficientStockError => e
      @status_message = e.message
      @status_variant = :error
    end

    # "Buy now" adds the item and goes straight to checkout.
    if params[:buy_now].present? && @status_variant == :success
      redirect_to new_checkout_path, status: :see_other and return
    end

    load_cart_items
    @in_bag_quantity = @cart_items.find { |cart_item| cart_item.product_id == @product.id }&.quantity

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: cart_path, flash: { flash_key(@status_variant) => @status_message } }
    end
  end

  def update
    cart_item = @cart.cart_items.find(params[:id])

    begin
      Carts::CartService.new(@cart).update_quantity(cart_item: cart_item, quantity: params[:quantity].to_i)
    rescue Carts::CartService::InsufficientStockError => e
      @cart_flash_message = e.message
    end

    load_cart_items

    respond_to do |format|
      format.turbo_stream
      format.html do
        if @cart_flash_message
          redirect_back fallback_location: cart_path, alert: @cart_flash_message
        else
          redirect_back fallback_location: cart_path, notice: "Your cart was updated."
        end
      end
    end
  end

  def destroy
    cart_item = @cart.cart_items.find(params[:id])
    Carts::CartService.new(@cart).remove_item(cart_item: cart_item)

    load_cart_items

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: cart_path, notice: "Removed from your cart." }
    end
  end

  def save_for_later
    cart_item = @cart.cart_items.find(params[:id])
    Carts::CartService.new(@cart).save_for_later(cart_item: cart_item)

    load_cart_items
    @saved_items = current_user.wishlist_items.includes(product: :category).order(created_at: :desc)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path, notice: "Saved to your wishlist." }
    end
  end

  private

  def set_cart
    @cart = current_user.cart
    authorize @cart, :update?
  end

  def load_cart_items
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
  end

  def flash_key(variant)
    variant == :success ? :notice : :alert
  end
end
