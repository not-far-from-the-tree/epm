class EventsController < ApplicationController
 
  load_and_authorize_resource :event

  def index
    respond_to do |format|
      format.html do
        @sections = []
        max = 10 # used for sections which do not need to show all
        if current_user.has_role? :admin
          @sections << { q: Event.awaiting_approval, name: 'Awaiting Approval' }
        end
        if current_user.has_role? :participant
          @sections << { q: current_user.open_invites, name: 'Invited' }
        end
        if current_user.has_role? :coordinator
          @sections << { q: current_user.coordinating_events.not_past, name: 'Coordinating' }
        end
        if current_user.has_role? :participant
          @sections << { q: current_user.participating_events.not_past, name: 'Attending' }
          @sections << { q: current_user.potential_events, name: 'May be Attending' }
        end
        if current_user.has_any_role? :coordinator, :admin
          @sections << { q: Event.where(coordinator_id: nil).not_past.not_cancelled, name: 'Needing a Coordinator' }
        end
        if current_user.has_role? :admin
          @sections << { q: Event.where.not(coordinator_id: nil).where('start IS NULL OR lat IS NULL').not_past.not_cancelled, name: 'Missing a Date or Location' }
        end
        if current_user.has_any_role? :admin, :participant
          q = Event.needing_participants
          q = q.participatable_by(current_user) unless current_user.has_role? :admin
          @sections << { q: q, name: 'Needing More Participants' }
        end
        if current_user.has_any_role? :admin, :participant
          q = Event.accepting_not_needing_participants.limit(max)
          q = q.participatable_by(current_user) unless current_user.has_role? :admin
          @sections << { q: q, name: 'Accepting More Participants' }
        end
        if current_user.has_any_role? :admin, :participant
          q = Event.participatable.not_past.where(reached_max: true).limit(max)
          q = q.participatable_by(current_user) unless current_user.has_role? :admin
          @sections << { q: q, name: 'Upcoming', id: 'full' }
          @sections[0..-2].each do |section| # add the word 'more' to the name if there were any events already listed
            if section[:q].any?
              @sections.last[:name] = "More #{@sections.last[:name]}"
              break
            end
          end
        end
        if current_user.has_role? :admin
          @sections << { q: Event.participatable.past.limit(max) , name: 'Past' }
        end
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

  def who
  end

  def new
    attrs = {}
    attrs[:start] = params['start_day'] if params['start_day']
    @event = Event.new(attrs)
  end

  def edit
  end

  def create
    redirect_to(root_path, notice: 'Event not saved.') and return if params['commit'].downcase == 'cancel'
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
    redirect_to(@event, notice: 'Event changes not saved.') and return if params['commit'].downcase == 'cancel'
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
        if params['commit'].downcase.include?('notify') && !(@event.past? && @event.prior['past?']) && users.any?
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
      params.require(:event).permit(:name, :description, :notes, :start, :start_day, :start_time_12, :start_time_p, :duration, :finish, :coordinator_id, :notify_of_changes, :status, :address, :lat, :lng, :hide_specific_location, :min, :max)
    end

end