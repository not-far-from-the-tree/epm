class EventsController < ApplicationController
 
  load_and_authorize_resource :event

  include ActionView::Helpers::TextHelper # needed for pluralize()

  def index
    respond_to do |format|
      format.html do
        if current_user.has_role? :admin
          # this 'section' doesn't match the pattern of the others so can't be put into @sections
          coordinators = User.coordinators_not_taking_attendance
          @coordinators_not_taking_attendance = coordinators if coordinators.any?
        end
        @sections = []
        max = 10 # used for sections which do not need to show all
        if current_user.has_role? :admin
          @sections << { q: Event.awaiting_approval, name: 'Awaiting Approval' }
        end
        if current_user.has_role? :participant
          @sections << { q: current_user.recommended_events, name: "Recommended #{Configurable.event.pluralize.titlecase}", id: 'recommended' }
        end
        if current_user.has_role? :coordinator
          @sections << { q: current_user.coordinating_events.needing_attendance_taken, name: 'Needing Attendance Taken' }
          @sections << { q: current_user.coordinating_events.not_past, name: "#{Configurable.event.pluralize.titlecase} Led By Me", id: 'coordinating' }
        end
        if current_user.has_role? :participant
          @sections << { q: current_user.participating_events.not_past, name: "#{Configurable.event.pluralize.titlecase} I’m Attending", id: 'attending' }
          @sections << { q: current_user.potential_events, name: "#{Configurable.event.pluralize.titlecase} I’m Waitlisted For", id: 'may_be_attending' }
        end
        if current_user.has_any_role? :coordinator, :admin
          @sections << { q: Event.where(coordinator_id: nil).not_past.not_cancelled, name: "#{Configurable.event.pluralize.titlecase} Needing #{Configurable.coordinator.titlecase.indefinitize}", id: 'needing_a_coordinator' }
        end
        if current_user.has_role? :admin
          @sections << { q: Event.where.not(coordinator_id: nil).where('start IS NULL OR lat IS NULL').not_past.not_cancelled, name: "#{Configurable.event.pluralize.titlecase} Missing a Date or Location", id: 'missing_info' }
        end
        if current_user.has_any_role? :admin, :participant
          q = Event.accepting_participants
          q = q.participatable_by(current_user).where.not(ward_id: current_user.user_wards.pluck(:ward_id)) unless current_user.has_role? :admin
          @sections << { q: q, name: "#{Configurable.event.pluralize.titlecase} Needing More #{Configurable.participant.pluralize.titlecase}", id: 'not_full' }

          q = Event.participatable.not_past.where(reached_max: true).limit(max)
          q = q.participatable_by(current_user) unless current_user.has_role? :admin
          @sections << { q: q, name: "#{Configurable.event.pluralize.titlecase} That Are Full (Join Waitlist)", id: 'full' }
        end
        if current_user.has_role? :admin
          @sections << { q: Event.participatable.past.limit(max) , name: "Past #{Configurable.event.pluralize.titlecase}", id: 'past' }
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
    @can_take_attendance = false
    @taking_attendance = false
    @invites = {}
    if @event.start
      if (current_user.has_role?(:admin) || @event.coordinator == current_user) && @event.can_accept_participants?
        eus = @event.event_users.where(status: EventUser.statuses_array(:invited, :not_attending)).group_by{|eu| eu.status}
        @invites['awaiting a response'] = (eus['invited'] || []).length
        @invites['declined'] = (eus['not_attending'] || []).length
        @invites['not yet sent'] = Invitation.where(event_id: @event.id).count
      end
      if Time.zone.now >= @event.start
        @can_take_attendance = can?(:take_attendance, @event) && @event.approved? && @event.event_users.where(status: EventUser.statuses_array(:attending, :attended, :no_show)).any?
        @taking_attendance = @can_take_attendance && (params['take_attendance'] || @event.event_users.where(status: EventUser.statuses[:attending]).any?)
      end
    end
  end

  def new
    attrs = {}
    attrs[:start] = "#{params['start_day']} #{Event.default_time}" if params['start_day']
    @event = Event.new(attrs)
  end

  def edit
  end

  def create
    redirect_to(root_path, notice: "#{Configurable.event.capitalize} not saved.") and return if params['commit'] && params['commit'].downcase == 'cancel'
    @event = Event.new event_params
    if @event.save
      if !@event.past?
        if @event.coordinator && @event.coordinator != current_user
          EventMailer.coordinator_assigned(@event).deliver
        elsif !@event.coordinator && @event.ward
          coordinators = User.coordinators.interested_in_ward(@event.ward).where.not(id: current_user.id)
          EventMailer.coordinator_needed(@event, coordinators).deliver if coordinators.any?
        end
      end
      redirect_to @event, notice: "#{Configurable.event.capitalize} saved."
    else
      render :new
    end
  end

  def update
    redirect_to(@event, notice: "#{Configurable.event.capitalize} changes not saved.") and return if params['commit'] && params['commit'].downcase == 'cancel'
    @event.track
    if @event.update event_params
      # send email notifications if appropriate
      unless @event.cancelled?
        users = @event.users.reject{|u| u == current_user}
        # alert admins if it's ready for approval
        if !@event.prior['awaiting_approval?'] && @event.awaiting_approval?
          admins = User.admins.reject{|u| u == current_user}
          if admins.any?
            # note: awaiting approval emails also sent from claim method
            users.reject!{|u| admins.include? u} # prevents emailing an admin twice if they are also a coordinator or a participant of this event
            EventMailer.awaiting_approval(@event, admins).deliver
          end
        end
        # alert coordinator being assigned
        if @event.coordinator && (@event.coordinator_id != @event.prior['coordinator_id']) && (@event.coordinator != current_user) && !@event.past?
          users.reject!{|u| u == @event.coordinator} # prevents emailing a coordinator twice when they are assigned an event which has significant changes
          EventMailer.coordinator_assigned(@event).deliver
        end
        # alert other attendees
        if params['commit'] && params['commit'].downcase.include?('notify') && !(@event.past? && @event.prior['past?']) && users.any?
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
      redirect_to @event, notice: "#{Configurable.event.capitalize} saved."
    else
      render :edit
    end
  end

  def approve
    if @event.proposed?
      @event.update status: :approved
      if @event.coordinator && @event.coordinator != current_user
        EventMailer.approve(@event).deliver
      end
      flash[:notice] = "#{Configurable.event.capitalize} approved."
      if @event.should_invite?
        if @event.invite > 0
          flash[:notice] += ' Invitations will be sent.'
        end
      end
    elsif @event.cancelled?
      flash[:notice] = "Cannot approve cancelled #{Configurable.event.pluralize}."
    end
    redirect_to @event
  end

  def claim
    was_awaiting_approval = @event.awaiting_approval?
    if @event.update coordinator_id: current_user.id
      if @event.awaiting_approval? && !was_awaiting_approval
        # awaiting approval emails also sent from update method
        admins = User.admins.reject{|u| u == current_user}
        EventMailer.awaiting_approval(@event, admins).deliver if admins.any?
      end
      flash[:notice] = 'You are now running this event.'
    else
      flash[:error] = 'You are not able to claim this event.'
    end
    redirect_to @event
  end

  def unclaim
    if @event.proposed? && @event.coordinator == current_user
      @event.update coordinator: nil
      flash[:notice] = 'You are no longer running this event.'
    end
    redirect_to @event
  end

  def ask_to_cancel
  end

  def cancel
    if params['commit'] && params['commit'] == "Cancel #{Configurable.event.titlecase}"
      @event.cancel params.require(:event).permit(:cancel_notes, :cancel_description)
      users = (@event.users + User.admins).reject{|u| u == current_user}
      users = users.partition{|u| u.ability.can?(:read_notes, @event)} # .first can read the note, .last can't
      EventMailer.cancel(@event, users.first).deliver if users.first.any?
      EventMailer.cancel(@event, users.last).deliver if users.last.any?
      flash[:notice] = "#{Configurable.event.capitalize} cancelled."
    else
      flash[:notice] = "#{Configurable.event.capitalize} not cancelled."
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

  def invite
    invites = @event.invite
    if invites > 0
      flash[:notice] = "#{pluralize invites, 'invitation'} will be sent."
    else
      flash[:notice] = 'No invitations sent.'
    end
    redirect_to who_event_path @event
  end

  def take_attendance
    params['attendance'] ||= []
    attended_eu_ids = params['attendance'].map{|eu_id, v| eu_id.to_i}
    @event.take_attendance attended_eu_ids
    redirect_to who_event_path(@event), notice: 'Attendance taken.'
  end

  private

    def event_params
      # should actually only enable :status to be set by admin. todo
      params.require(:event).permit(:name, :description, :notes, :start, :start_day, :start_time_12, :start_time_p, :duration, :finish, :coordinator_id, :notify_of_changes, :status, :address, :lat, :lng, :hide_specific_location, :min, :max, :ward_id)
    end

end
