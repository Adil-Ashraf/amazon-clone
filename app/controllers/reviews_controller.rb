class ReviewsController < ApplicationController
  before_action :require_login

  def create
    product = Product.find(params[:product_id])
    review = Reviews::CreateService.new(user: current_user, product: product)
      .call(rating: review_params[:rating].to_i, body: review_params[:body])

    if review.persisted?
      redirect_to product_path(product, anchor: "reviews"), notice: "Thanks for your review."
    else
      redirect_to product_path(product, anchor: "reviews"), alert: review.errors.full_messages.to_sentence
    end
  rescue Reviews::CreateService::NotPurchasedError => e
    redirect_to product_path(product, anchor: "reviews"), alert: e.message
  end

  private

  def review_params
    params.require(:review).permit(:rating, :body)
  end
end
