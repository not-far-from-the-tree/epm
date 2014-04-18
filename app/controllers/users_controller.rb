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
    if role.present?
      if role == 'none'
        @role = role
        @users = @users.roleless
      elsif User.respond_to?(role.downcase)
        @role = role
        @users = @users.send(role.downcase)
      end
    end

    respond_to do |format|
      format.html { @users = @users.page(params[:page]).per(20) }
      format.csv { send_data @users.csv }
    end
  end

  def show
    @past_coordinating = @user.coordinating_events.past
    @past_participating = @user.participating_events.past
  end

  def edit
  end

  def update
    if params['commit'].downcase == 'cancel'
      redirect_to @user, notice: 'Changes not saved.'
    elsif @user.update(params.require(:user).permit(:name, :email, :phone, :description, :address, :lat, :lng))
      redirect_to @user, notice: 'Profile was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def deactivate
    @user.roles.each do |role|
      role.destroyed_by_self = current_user == @user
      role.destroy
    end
    if @user.roles.reload.none?
      flash[:notice] = 'Your account has been deactivated.'
    else
      flash[:notice] = 'Your account was unable to be deactivated.'
    end
    redirect_to @user
  end

end