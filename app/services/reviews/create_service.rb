module Reviews
  class CreateService
    class NotPurchasedError < StandardError; end

    def initialize(user:, product:)
      @user = user
      @product = product
    end

    # Only people who bought the product can review it, so every rating on
    # the site comes from a real order. Returns the review; an invalid one
    # (blank body, second review) comes back unsaved with its errors.
    def call(rating:, body:)
      raise NotPurchasedError, "Only customers who bought this product can review it." unless @user.purchased?(@product)

      review = @product.reviews.new(user: @user, rating: rating, body: body)

      ActiveRecord::Base.transaction do
        next unless review.save

        @product.update!(rating_average: @product.reviews.average(:rating).round(1))
      end

      review
    end
  end
end
