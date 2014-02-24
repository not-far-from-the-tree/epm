class UsersController < ApplicationController

  load_and_authorize_resource :user

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

end
