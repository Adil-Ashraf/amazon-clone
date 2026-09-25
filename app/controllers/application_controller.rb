class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_user, :logged_in?, :cart_item_count, :nav_categories

  private

  def pundit_user
    current_user
  end

  def user_not_authorized
    redirect_to root_path, alert: "You are not authorized to do that."
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  # Signing in always starts a fresh session, so a session id set before
  # login (session fixation) can't be reused. Recently viewed products are
  # the only guest data worth keeping, so they carry over.
  def sign_in(user)
    recently_viewed = session[:recently_viewed]
    reset_session
    session[:recently_viewed] = recently_viewed if recently_viewed
    session[:user_id] = user.id
  end

  def cart_item_count
    current_user&.cart&.cart_items&.sum(:quantity) || 0
  end

  # Every category for the header menu, largest first.
  def nav_categories
    @nav_categories ||= Category.left_joins(:products).group(:id).order(Arel.sql("COUNT(products.id) DESC"), :name).to_a
  end

  def require_login
    return if logged_in?

    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  # What the signed-in shopper already has for a set of product cards:
  # product_id => quantity in the cart, and product_id => wishlist item id.
  def load_card_state(products)
    ids = products.map(&:id).uniq
    @bag_quantities = {}
    @wishlist_ids = {}
    return unless current_user && ids.any?

    @bag_quantities = CartItem.joins(:cart).where(carts: { user_id: current_user.id }, product_id: ids).pluck(:product_id, :quantity).to_h
    @wishlist_ids = current_user.wishlist_items.where(product_id: ids).pluck(:product_id, :id).to_h
  end

  # A top-rated product photo for the sign-in and sign-up brand panel.
  def showcase_product
    Product.with_photo.includes(:category).top_rated.first
  end

  RECENTLY_VIEWED_LIMIT = 8

  def recently_viewed_ids
    Array(session[:recently_viewed]).map(&:to_i)
  end

  def remember_viewed(product)
    session[:recently_viewed] = ([ product.id ] + recently_viewed_ids).uniq.first(RECENTLY_VIEWED_LIMIT)
  end

  def recently_viewed_products(excluding: nil)
    ids = recently_viewed_ids - [ excluding&.id ]
    Product.includes(:category).where(id: ids).index_by(&:id).values_at(*ids).compact
  end
end
