class UsersController < ApplicationController

  load_and_authorize_resource :user

  def me
    redirect_to current_user
  end
  def my_wards
    redirect_to edit_user_path(current_user, anchor: 'wards')
  end

  def index
    @users = User.by_name
    @q = params['q'] ? params['q'].strip : nil
    @users = @users.search(@q) if @q.present?
    show_only = params['show_only']
    if show_only.present? && User.respond_to?(show_only.downcase)
      @show_only = show_only
      @users = @users.send(show_only.downcase)
    end

    respond_to do |format|
      format.html { @users = @users.page(params[:page]).per(20) }
      format.csv { send_data User.csv(@users) }
    end
  end

  def map
    @layers = [
      {
          points: User.participants.geocoded.select('lat, lng'),
          name: Configurable.participant.pluralize.titlecase
      },
      {
          points: User.coordinators.geocoded.select('lat, lng'),
          name: Configurable.coordinator.pluralize.titlecase
      }
    ].reject{|h| h[:points].length < 10}
    codes = []
    @layers.each do  |h|
      n = 0
      while codes.include? h[:name][0..n]
        n+= 1
      end
      h[:code] = h[:name][0..n]
      codes << h[:code]
    end
  end

  def destroy
    if @user.destroy
      redirect_to action: "index", notice: 'User deleted.'
    else 
      redirect_to @user, notice: 'User not deleted.'
    end
  end

  def show
    @past_coordinating = @user.coordinating_events.past
  end

  def edit
  end

  def update
    if params['commit'] && params['commit'].downcase == 'cancel'
      redirect_to @user, notice: 'Changes not saved.'
    elsif @user.update params.require(:user).permit(:fname, :lname, :email, :phone, :address, :snail_mail, :lat, :lng, :home_ward, :participate_in_picks, :add_trees, :ladder, :password_confirmation, :waiver, :admin_notes, :do_not_contact_reason, ward_ids: [])
      # note the params permitted above need to also be listed in the registrations controller
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

  def invite 
    @user = User.find(params['user_id'])
    if params['event_id']
      @event = Event.find(params['event_id'])
      eu = @event.event_users.create user: @user, status: :invited
      if eu.valid?
        Invitation.create event: @event, user: @user, send_by: Time.zone.now
      end
      redirect_to @user, notice: 'User invited.'
    else
      @events = Event.accepting_participants
          .joins("LEFT JOIN event_users ON event_users.event_id = events.id")
          #.where.not("event_users.user_id = " + @user.id.to_s)
          #.group("events.id")
    end
  end

end