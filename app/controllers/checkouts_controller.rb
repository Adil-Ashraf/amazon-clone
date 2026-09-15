class CheckoutsController < ApplicationController
  before_action :require_login

  def new
    @cart = current_user.cart
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
    @order = current_user.orders.new(shipping_name: current_user.name)

    redirect_to cart_path, alert: "Your cart is empty." if @cart_items.none?
  end

  def create
    order = Orders::CheckoutService.new(user: current_user, shipping_attributes: shipping_params).call
    redirect_to order_path(order), notice: "Order placed! Thanks for your purchase."
  rescue Orders::CheckoutService::EmptyCartError => e
    redirect_to cart_path, alert: e.message
  rescue Orders::CheckoutService::InsufficientStockError => e
    render_new_with_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    render_new_with_error(nil, order: e.record)
  end

  private

  def shipping_params
    params.require(:order).permit(
      :shipping_name, :shipping_address_line1, :shipping_address_line2,
      :shipping_city, :shipping_state, :shipping_zip
    ).to_h.symbolize_keys
  end

  def render_new_with_error(message, order: nil)
    @cart = current_user.cart
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
    @order = order || current_user.orders.new(shipping_params)
    flash.now[:alert] = message if message
    render :new, status: :unprocessable_entity
  end
end
