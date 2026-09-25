class PagesController < ApplicationController
  PAGES = %w[help shipping returns about contact privacy terms sell].freeze

  # The route only matches PAGES; the template name still comes from the
  # constant, never from the request.
  def show
    page = PAGES.find { |name| name == params[:page] } or raise ActionController::RoutingError, "Not Found"
    render page
  end
end
