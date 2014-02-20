class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update]

  def show
  end

  def edit
  end

  def update
    if @user.update(params.require(:user).permit(:name, :email, :phone, :description))
      redirect_to @user, notice: 'Profile was successfully updated.'
    else
      render action: 'edit'
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

end
