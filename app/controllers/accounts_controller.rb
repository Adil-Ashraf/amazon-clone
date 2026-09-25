class AccountsController < ApplicationController
  before_action :require_login

  def show
    @recent_orders = current_user.orders.order(created_at: :desc).limit(3)
    @last_order = @recent_orders.first
    @orders_count = current_user.orders.count
    @wishlist_count = current_user.wishlist_items.count
    @reviews_count = current_user.reviews.count
  end
end
