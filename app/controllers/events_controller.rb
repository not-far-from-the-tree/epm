class EventsController < ApplicationController
 
  load_and_authorize_resource :event

  def index
    @joinable = Event.participatable.not_past.not_attended_by(current_user)
  end

  def past
    @events = Event.past
  end

  def show
  end

  def new
    @event = Event.new
  end

  def edit
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      if @event.coordinator && @event.coordinator != current_user
        EventMailer.coordinator_assigned(@event).deliver
      end
      redirect_to @event, notice: 'Event was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    @event.assign_attributes event_params
    new_coordinator = @event.coordinator_id_changed? && @event.coordinator
    if @event.save
      if new_coordinator && @event.coordinator != current_user
        EventMailer.coordinator_assigned(@event).deliver
      end
      redirect_to @event, notice: 'Event was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @event.destroy
    redirect_to events_url, notice: 'Event was successfully deleted.'
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