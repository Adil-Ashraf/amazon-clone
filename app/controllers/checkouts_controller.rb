class CheckoutsController < ApplicationController
  before_action :require_login

  layout "checkout"

  def new
    @cart = current_user.cart
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
    @order = current_user.orders.new(last_shipping_address || { shipping_name: current_user.name })

    redirect_to cart_path, alert: "Your cart is empty." if @cart_items.none?
  end

  def create
    order = Orders::CheckoutService.new(user: current_user, shipping_attributes: shipping_params).call
    # One-time flag: the first view of this order shows the confirmation panel.
    redirect_to order_path(order), flash: { order_placed: order.id }
  rescue Orders::CheckoutService::EmptyCartError => e
    redirect_to cart_path, alert: e.message
  rescue Orders::CheckoutService::InsufficientStockError => e
    render_new_with_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    render_new_with_error(nil, order: e.record)
  end

  private

  SHIPPING_FIELDS = %i[shipping_name shipping_address_line1 shipping_address_line2 shipping_city shipping_state shipping_zip].freeze

  # Prefill the form with the address from the shopper's last order.
  def last_shipping_address
    current_user.orders.order(created_at: :desc).first&.slice(*SHIPPING_FIELDS)
  end

  def shipping_params
    params.require(:order).permit(*SHIPPING_FIELDS).to_h.symbolize_keys
  end

  def render_new_with_error(message, order: nil)
    @cart = current_user.cart
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
    @order = order || current_user.orders.new(shipping_params)
    flash.now[:alert] = message if message
    render :new, status: :unprocessable_entity
  end
end
