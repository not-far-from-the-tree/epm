class EventsController < ApplicationController
 
  load_and_authorize_resource :event

  def index
    respond_to do |format|
      format.html do
        if current_user.has_role? :admin
          @awaiting_approval = Event.awaiting_approval
        end
        if current_user.has_role? :admin
          @missing_title = 'Events with No Date or No Coordinator'
          @missing_parts = Event.not_past.not_cancelled.where('coordinator_id IS NULL OR start IS NULL')
        elsif current_user.has_role? :coordinator
          @missing_title = 'Events with No Coordinator'
          @missing_parts = Event.not_past.not_cancelled.where('coordinator_id IS NULL')
        end
        @joinable = Event.participatable.not_past.not_attended_by(current_user).limit(10)
      end
      format.ics do
        # todo: implement access token https://blog.nop.im/entries/calendar-feed-with-rails
        cal = Icalendar::Calendar.new
        cal.properties["X-WR-CALNAME"] = Configurable.title
        cal.properties["NAME"] = Configurable.title
        Event.with_date.each {|event| cal.add_event event.to_ical(request.host) }
        render text: cal.to_ical
      end
    end
  end

  def calendar
    @events = Event.not_cancelled.in_month params['year'], params['month']
  end

  def show
  end

  def new
    attrs = {status: :approved}
    attrs[:start] = params['start_day'] if params['start_day']
    @event = Event.new(attrs)
  end

  def edit
    @event.notify_of_changes = true
  end

  def create
    @event = Event.new event_params
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
    event_was_past = @event.past?
    event_was_awaiting_approval = @event.awaiting_approval?
    @event.assign_attributes event_params
    users = @event.users.reject{|u| u == current_user}
    new_coordinator = @event.coordinator_id_changed? && @event.coordinator
    changed_significantly = @event.changed_significantly?
    notes_changed = @event.notes_changed?
    if @event.save
      # send email notifications if appropriate
      unless @event.cancelled?
        # alert admins if it's ready for approval
        if !event_was_awaiting_approval && @event.awaiting_approval?
          admins = User.admins.reject{|u| u == current_user}
          if admins.any?
            users.reject!{|u| admins.include? u} # prevents emailing an admin twice if they are also a coordinator or a participant of this event
            EventMailer.awaiting_approval(@event, admins).deliver
          end
        end
        # alert coordinator being assigned
        if new_coordinator && @event.coordinator != current_user
          users.reject!{|u| u == @event.coordinator} # prevents emailing a coordinator twice when they are assigned an event which has significant changes
          EventMailer.coordinator_assigned(@event).deliver
        end
        # alert other attendees
        if @event.notify_of_changes.present? && !(@event.past? && event_was_past) && users.any?
          users = users.partition{|u| u.ability.can?(:read_notes, @event)} # .first can read the note, .last can't
          if (changed_significantly || notes_changed) && users.first.any?
            EventMailer.change(@event, users.first).deliver
          end
          if changed_significantly && users.last.any?
            EventMailer.change(@event, users.last).deliver
          end
        end
      end
      redirect_to @event, notice: 'Event saved.'
    else
      render :edit
    end
  end

  def approve
    if @event.proposed?
      @event.update(status: :approved)
      if @event.coordinator && @event.coordinator != current_user
        EventMailer.approve(@event).deliver
      end
      flash[:notice] = 'Event approved.'
    else
      flash[:notice] = 'Cannot approve cancelled events.'
    end
    redirect_to @event
  end

  def destroy
    @event.update(status: :cancelled)
    users = (@event.users + User.admins).reject{|u| u == current_user}
    EventMailer.cancel(@event, users).deliver if users.any?
    redirect_to @event, notice: 'Event cancelled.'
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
      # should actually only enable :status to be set by admin. todo
      params.require(:event).permit(:name, :description, :notes, :start, :start_day, :start_time_12, :start_time_p, :duration, :finish, :coordinator_id, :notify_of_changes, :status)
    end

end