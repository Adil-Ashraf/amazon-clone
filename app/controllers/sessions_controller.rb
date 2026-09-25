class SessionsController < ApplicationController
  def new
    @showcase = showcase_product
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user
      sign_in(user)
      redirect_to root_path, notice: "Welcome back, #{user.name.split.first}."
    else
      @sign_in_error = "That email and password don't match an account. Check them and try again."
      @showcase = showcase_product
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You have signed out."
  end
end
