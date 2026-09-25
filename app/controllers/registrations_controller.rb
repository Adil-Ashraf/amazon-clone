class RegistrationsController < ApplicationController
  def new
    @user = User.new
    @showcase = showcase_product
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      @user.create_cart!
      sign_in(@user)
      redirect_to root_path, notice: "Welcome to Aisle Market, #{@user.name.split.first}."
    else
      @showcase = showcase_product
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
