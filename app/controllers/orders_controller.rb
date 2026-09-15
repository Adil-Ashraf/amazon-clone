class OrdersController < ApplicationController
  before_action :require_login

  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  def show
    @order = current_user.orders.find(params[:id])
    authorize @order
  end
end
