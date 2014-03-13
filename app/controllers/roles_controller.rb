class RolesController < ApplicationController

  load_and_authorize_resource :user
  load_and_authorize_resource :role, through: :user, shallow: true

  def create
    if @role.save
      flash[:notice] = 'Role added.'
    end
    redirect_to @user
  end

  def destroy
    if @role.destroy
      flash[:notice] = 'Role removed.'
    else
      flash[:notice] = @role.errors.full_messages.join ', '
    end
    redirect_to @role.user
  end

  def role_params
    params.require(:role).permit(:name)
  end

end