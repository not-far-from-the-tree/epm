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
    eu = @event.event_users.find_or_initialize_by(user_id: current_user.id)

    # determine what string to use to describe the existing rsvp
    @attend_str = nil
    is_the_coordinator = current_user == @event.coordinator
    if current_user.has_role?(:participant) || current_user.has_role?(:coordinator) || eu.status
      @attend_str = 'You '
      if @event.past?
        @attend_str += (eu.attending? || eu.attended? || is_the_coordinator) ? 'attended' : 'did not attend'
      elsif eu.waitlisted?
        @attend_str += 'are on the waitlist for'
      elsif eu.requested?
        @attend_str += 'have requested to attend'
      elsif eu.attending? || is_the_coordinator
        @attend_str += 'are attending'
      elsif eu.invited?
        @attend_str += 'have been invited to attend'
      else
        @attend_str += 'are not attending'
      end
      @attend_str += ' this event.'
    end

    # determine what buttons to show to change rsvp
    @buttons = {}
    if @event.participatable_by? current_user
      if [nil, 'not_attending', 'withdrawn', 'cancelled', 'invited'].include? eu.status
        # todo: this does not handle events where a participant must first request to join if they haven't been invited, which would change the 'attend' text for statuses that are not :invited
        @buttons[:attend] = @event.full? ? 'Add To Waitlist' : 'Attend'
        @buttons[:unattend] = 'Will Not Attend' if eu.invited?
      elsif eu.waitlisted? || eu.requested?
        @buttons[:unattend] = 'Withdraw Request'
      elsif eu.attending?
        @buttons[:unattend] = 'Cancel'
      end
    end

  end

  def new
    attrs = {}
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
    @event.track
    if @event.update event_params
      # send email notifications if appropriate
      unless @event.cancelled?
        users = @event.users.reject{|u| u == current_user}
        # alert admins if it's ready for approval
        if !@event.prior['awaiting_approval?'] && @event.awaiting_approval?
          admins = User.admins.reject{|u| u == current_user}
          if admins.any?
            users.reject!{|u| admins.include? u} # prevents emailing an admin twice if they are also a coordinator or a participant of this event
            EventMailer.awaiting_approval(@event, admins).deliver
          end
        end
        # alert coordinator being assigned
        if @event.coordinator && (@event.coordinator_id != @event.prior['coordinator_id']) && (@event.coordinator != current_user)
          users.reject!{|u| u == @event.coordinator} # prevents emailing a coordinator twice when they are assigned an event which has significant changes
          EventMailer.coordinator_assigned(@event).deliver
        end
        # alert other attendees
        if @event.notify_of_changes.present? && !(@event.past? && @event.prior['past?']) && users.any?
          users = users.partition{|u| u.ability.can?(:read_notes, @event)} # .first can read the note, .last can't
          changed_significantly = @event.changed_significantly?
          if (changed_significantly || (@event.notes != @event.prior['notes'])) && users.first.any?
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

  def ask_to_cancel
  end

  def cancel
    if params['commit'] == 'Cancel Event'
      @event.update params.require(:event).permit(:cancel_notes, :cancel_description).merge(status: :cancelled)
      users = (@event.users + User.admins).reject{|u| u == current_user}
      users = users.partition{|u| u.ability.can?(:read_notes, @event)} # .first can read the note, .last can't
      EventMailer.cancel(@event, users.first).deliver if users.first.any?
      EventMailer.cancel(@event, users.last).deliver if users.last.any?
      flash[:notice] = 'Event cancelled.'
    else
      flash[:notice] = 'Event not cancelled.'
    end
    redirect_to @event
  end

  def attend
    eu = @event.attend current_user
    EventMailer.attend(@event, current_user).deliver if eu.attending?
    # note: no need for flash messages as that is redundant with the rsvp text in events#show
    redirect_to @event
  end

  def unattend
    @event.unattend current_user
    # note: no need for flash messages as that is redundant with the rsvp text in events#show
    redirect_to @event
  end

  include ActionView::Helpers::TextHelper # needed for pluralize()
  def invite
    num =  params['number'].to_i
    people = @event.invitable_participants.limit([num, Event.max_invitable].min)
    if num > 0 && people.any?
      people.each do |participant|
        @event.event_users.create user: participant, status: :invited
      end
      EventMailer.invite(@event, people).deliver
      flash[:notice] = "#{pluralize people.length, 'invitation'} sent."
    else
      flash[:notice] = 'No invitations sent.'
    end
    redirect_to @event
  end

  private

    def event_params
      # should actually only enable :status to be set by admin. todo
      params.require(:event).permit(:name, :description, :notes, :start, :start_day, :start_time_12, :start_time_p, :duration, :finish, :coordinator_id, :notify_of_changes, :status, :address, :lat, :lng, :min, :max)
    end

end