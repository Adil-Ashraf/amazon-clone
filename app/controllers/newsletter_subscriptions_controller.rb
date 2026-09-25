class NewsletterSubscriptionsController < ApplicationController
  def create
    @subscription = NewsletterSubscription.find_or_initialize_by(email: params[:email].to_s.strip.downcase)
    @subscribed = @subscription.persisted? || @subscription.save

    respond_to do |format|
      format.turbo_stream
      format.html do
        if @subscribed
          redirect_back fallback_location: root_path, notice: "You're on the list."
        else
          redirect_back fallback_location: root_path, alert: "Please enter a valid email address."
        end
      end
    end
  end
end
