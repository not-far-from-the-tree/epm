class EventsController < ApplicationController
 
  load_and_authorize_resource :event

  def index
    @joinable = Event.participatable.not_past.not_attended_by(current_user)
  end

  def calendar
    @events = Event.in_month params['year'], params['month']
  end

  def show
  end

  def new
    attrs = {}
    attrs[:start] = params['start_day'] if params['start_day']
    @event = Event.new(attrs)
  end

  def edit
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      if @event.coordinator && @event.coordinator != current_user
        EventMailer.coordinator_assigned(@event).deliver
      end
      redirect_to @event, notice: 'Event saved.'
    else
      render :new
    end
  end

  def update
    @event.assign_attributes event_params
    users = @event.users.reject{|u| u == current_user}
    new_coordinator = @event.coordinator_id_changed? && @event.coordinator
    changed_significantly = @event.changed_significantly?
    if @event.save
      if new_coordinator && @event.coordinator != current_user
        users.reject!{|u| u == @event.coordinator} # prevents emailing a coordinator twice when they are assigned an event which has significant changes
        EventMailer.coordinator_assigned(@event).deliver
      end
      EventMailer.change(@event, users).deliver if users.any? && changed_significantly
      redirect_to @event, notice: 'Event saved.'
    else
      render :edit
    end
  end

  def destroy
    users = @event.users.reject{|u| u == current_user}
    if @event.destroy
      EventMailer.cancel(@event, users).deliver if users.any?
      redirect_to events_url, notice: "#{@event.display_name} deleted."
    else
      redirect_to @event, notice: 'Unable to delete this event.'
    end
  end

  def attend
    if @event.event_users.create user: current_user # this will fail if already attending but that's fine
      EventMailer.attend(@event, current_user).deliver
    end
    redirect_to @event, notice: 'You are now attending this event.'
  end

  def unattend
    # if user is already not attending this event, it does nothing and shows the same message which is fine
    @event.event_users.where(user: current_user).destroy_all
    redirect_to @event, notice: 'You are no longer attending this event.'
  end

  private

    def event_params
      params.require(:event).permit(:name, :description, :notes, :start, :start_day, :start_time, :duration, :finish, :coordinator_id)
    end

end