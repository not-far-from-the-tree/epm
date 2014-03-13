class UsersController < ApplicationController

  load_and_authorize_resource :user

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
    @upcoming = @user.events.not_past
    @past = @user.events.past
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