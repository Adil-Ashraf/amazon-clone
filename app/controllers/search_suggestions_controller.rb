# Typeahead for the header search box: the first few matches from the same
# pg_search scope the catalog uses, rendered into the box's Turbo Frame.
class SearchSuggestionsController < ApplicationController
  LIMIT = 6
  MIN_QUERY_LENGTH = 2
  # One frame per header search box (desktop, mobile). The id comes from
  # Turbo's request header, so it's only ever one of these.
  FRAME_IDS = %w[search_suggestions mobile_search_suggestions].freeze

  def index
    @frame_id = FRAME_IDS.find { |id| id == request.headers["Turbo-Frame"] } || FRAME_IDS.first
    @query = params[:query].to_s.strip

    if @query.length >= MIN_QUERY_LENGTH
      @products = Product.search_full_text(@query).includes(:category).limit(LIMIT).to_a
    else
      @products = []
    end
  end
end
