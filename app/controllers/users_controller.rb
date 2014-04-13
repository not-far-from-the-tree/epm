class UsersController < ApplicationController

  load_and_authorize_resource :user

  def me
    redirect_to current_user
  end

  def index
    @users = User.by_name
    @q = params['q'] ? params['q'].strip : nil
    @users = @users.search(@q) if @q.present?
    role = params['role']
    if role.present? && User.respond_to?(role.downcase)
      @role = role
      @users = @users.send(role.downcase)
    end

    respond_to do |format|
      format.html { @users = @users.page(params[:page]).per(20) }
      format.csv { send_data @users.csv }
    end
  end

  def show
    @past = @user.events.past
  end

  def edit
  end

  def update
    if @user.update(params.require(:user).permit(:name, :email, :phone, :description, :address, :lat, :lng))
      redirect_to @user, notice: 'Profile was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def deactivate
    if @user.roles.destroy_all
      flash[:notice] = 'Your account has been deactivated.'
    else
      flash[:notice] = 'Your account was unable to be deactivated.'
    end
    redirect_to @user
  end

end