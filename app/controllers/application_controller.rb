class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_user, :logged_in?, :cart_item_count

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

  def cart_item_count
    current_user&.cart&.cart_items&.sum(:quantity) || 0
  end

  def require_login
    return if logged_in?

    redirect_to new_session_path, alert: "Please sign in to continue."
  end
end
