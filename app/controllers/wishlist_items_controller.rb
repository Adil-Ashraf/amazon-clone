class WishlistItemsController < ApplicationController
  before_action :require_login

  def index
    @wishlist_items = load_wishlist_items
    load_card_state(@wishlist_items.map(&:product))
  end

  def create
    @product = Product.find(params[:product_id])
    @wishlist_item = current_user.wishlist_items.find_or_create_by!(product: @product)
    respond_with_toggle("Saved to your wishlist")
  rescue ActiveRecord::RecordNotUnique
    @wishlist_item = current_user.wishlist_items.find_by!(product: @product)
    respond_with_toggle("Saved to your wishlist")
  end

  def destroy
    wishlist_item = current_user.wishlist_items.find(params[:id])
    authorize wishlist_item
    wishlist_item.destroy!
    @product = wishlist_item.product
    @wishlist_item = nil
    respond_with_toggle("Removed from your wishlist")
  end

  private

  def load_wishlist_items
    current_user.wishlist_items.includes(product: :category).order(created_at: :desc)
  end

  def respond_with_toggle(message)
    @message = message
    @wishlist_items = load_wishlist_items
    load_card_state(@wishlist_items.map(&:product))

    respond_to do |format|
      format.turbo_stream { render :toggle }
      format.html { redirect_back fallback_location: wishlist_items_path, notice: message }
    end
  end
end
