class OrdersController < ApplicationController
  before_action :require_login

  def index
    @status_filter = params[:status] if Order::STATUS_GROUPS.key?(params[:status])
    orders = current_user.orders.includes(order_items: :product).order(created_at: :desc)
    orders = orders.where(status: Order::STATUS_GROUPS.fetch(@status_filter)) if @status_filter
    @orders = orders
  end

  def show
    @order = current_user.orders.find(params[:id])
    authorize @order
    @order_items = @order.order_items.includes(product: :category)
    @just_placed = flash[:order_placed] == @order.id
  end
end
