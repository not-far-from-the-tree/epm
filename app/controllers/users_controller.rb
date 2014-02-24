class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update]

  def show
    if @user.has_role? :participant
      @upcoming = @user.events.not_past
      @past = @user.events.past
    end
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
