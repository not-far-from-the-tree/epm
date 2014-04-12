require 'spec_helper'

describe Event do

  context "attributes with permissions" do

    context "display name" do

      it "has a display name with some text" do
        expect(build(:event).display_name).not_to be_blank
      end

      it "has a display name using the description when no name is given" do
        expect(build(:event, name: nil, description: 'foo').display_name).to eq 'foo'
      end

      it "has a display name using the address when no name or description is given" do
        e = build :event, name: nil, description: nil, address: '123 fake street', no_geocode: true
        expect(e.display_name).to eq '123 fake street'
      end

      it "does not have a display name using the address if hiding address from non-attending participants with nobody specified" do
        e = build :event, name: nil, description: nil, address: '123 fake street', no_geocode: true, hide_specific_location: true
        expect(e.display_name).not_to eq '123 fake street'
      end

      it "has a display name using the address for admins even if hiding address from non-attending participants" do
        e = build :event, name: nil, description: nil, address: '123 fake street', no_geocode: true, hide_specific_location: true
        expect(e.display_name create :admin).to eq '123 fake street'
      end

      it "has a display name using the address for participants only when attending if hiding otherwise" do
        u = create :participant
        e = create :participatable_event, name: nil, description: nil, address: '123 fake street', no_geocode: true, hide_specific_location: true
        expect(e.display_name u).not_to eq '123 fake street'
        e.attend u
        expect(e.display_name u).to eq '123 fake street'
      end

    end

    context "coordinates" do

      it "rounds coordinates to 2 decimal places for non-attending participants and coordinators" do
        n = 50.5092
        rounded = [BigDecimal.new(50.51, 6), BigDecimal.new(50.51, 6)]
        not_rounded = [BigDecimal.new(n, 6), BigDecimal.new(n, 6)]
        participant = create :participant
        e = create :participatable_event, lat: n, lng: n, hide_specific_location: true
        expect(e.coords participant).to eq rounded
        expect(e.coords create(:coordinator)).to eq rounded
        e.attend participant
        expect(e.coords participant).to eq not_rounded
        expect(e.coords e.coordinator).to eq not_rounded
      end

      it "does not round coordinates for admin" do
        n = 50.5092
        e = build :participatable_event, lat: n, lng: n, hide_specific_location: true
        expect(e.coords create(:admin)).to eq [BigDecimal.new(n, 6), BigDecimal.new(n, 6)]
      end

      it "does not round coordinates for events without hide_specific_location" do
        n = 50.5092
        e = build :participatable_event, lat: n, lng: n, hide_specific_location: false
        expect(e.coords).to eq [BigDecimal.new(n, 6), BigDecimal.new(n, 6)]
      end

    end

  end

  context "significant attributes" do

    it "is significantly changed when changing the start time" do
      e = create :event
      e.track
      e.update start: e.start - 1.hour
      expect(e.changed_significantly?).to be_true
    end

    it "is not significantly changed when changing the coordinator" do
      e = create :event
      e.track
      e.update coordinator_id: create(:coordinator).id
      expect(e.changed_significantly?).to be_false
    end

  end

  context "validity and normalization" do

    it "is invalid without a name, description, start, or address/coords" do
      empty_hash = { start: nil, name: nil, description: nil, address: nil, lat: nil, lng: nil }
      expect(build :event, empty_hash).not_to be_valid
      expect(build :event, empty_hash.merge(start: Time.zone.now)).to be_valid
      expect(build :event, empty_hash.merge(name: 'some name')).to be_valid
      expect(build :event, empty_hash.merge(description: 'some description')).to be_valid
      expect(build :event, empty_hash.merge(address: '123 fake street', no_geocode: true)).to be_valid
      expect(build :event, empty_hash.merge(lat: 40, lng: -80)).to be_valid
      expect(build :event, empty_hash.merge(lat: 40)).not_to be_valid
    end

    it "is invalid with a zero duration" do
      expect(build :event, duration: 0).not_to be_valid
    end

    it "is invalid without a finish later than the start" do
      event = build :event
      event.finish = event.start - 1.day
      expect(event).not_to be_valid
    end

    it "invalid with a start and no finish" do
      expect(build :event, start: Time.zone.now, finish: nil).not_to be_valid
    end

    it "is invalid with a maximum below the minimum" do
      expect(build :event, min: 10, max: 5).not_to be_valid
    end

    it "is valid with a latitude in range" do
      expect(build :event, lat: 40, lng: -80).to be_valid
    end

    it "is invalid with a latitude out of range" do
      expect(build :event, lat: 3000, lng: -80).not_to be_valid
    end

    # all fields should be stripped, this just tests two (excessive to check them all)
    context "normalizing attributes" do

      it "strips the name" do
        expect(create(:event, name: "  Stuff\n").name).to eq 'Stuff'
      end

      it "nullifies empty description" do
        expect(create(:event, description: "\r\n ").description).to be_nil
      end

    end

  end

  context "geocoding" do

    it "geocodes an address" do
      e = build :event, address: '1600 Pennsylvania Avenue, Washington, DC'
      e.valid? # triggers geocoding
      expect(e.lat).to be_within(1).of(38)
      expect(e.lng).to be_within(1).of(-77)
    end

    it "geocodes an address with newlines" do
      e = build :event, address: "1600 Pennsylvania Avenue\nWashington, DC"
      e.valid? # triggers geocoding
      expect(e.lat).to be_within(1).of(38)
      expect(e.lng).to be_within(1).of(-77)
    end

    it "does not override given coordinates" do
      e = build :event, address: '1600 Pennsylvania Avenue, Washington, DC', lat: 40, lng: -75
      e.valid? # triggers geocoding
      expect(e.lat).to eq 40
      expect(e.lng).to eq -75
    end

  end

  context "time methods" do

    it "responds properly to past? method" do
      expect(build(:event).past?).to be_false
      expect(build(:past_event).past?).to be_true
      expect(build(:event, start: nil).past?).to be_nil
    end

    it "sets finish when given a duration" do
      now = Time.zone.now
      expect(build(:event, start: now, duration: 1.hour).finish).to eq (now + 1.hour)
      expect(build(:event, start: now, duration: 8.hours).finish).to eq (now + 8.hours)
    end

    it "properly calculates duration" do
      expect(build(:event, start: Time.zone.now, duration: nil, finish: Time.zone.now + 1.hour).duration).to eq 1.hour.to_i
      expect(build(:event, start: Time.zone.now, duration: nil, finish: Time.zone.now + 8.hours).duration).to eq 8.hours.to_i
    end

    it "properly calculates time until" do
      expect(build(:event, start: nil).time_until).to be_nil
      expect(build(:event, start: 1.month.from_now).time_until).to be_within(1.minute).of(1.month)
      expect(build(:event, start: 2.weeks.ago).time_until).to be_within(1.minute).of(- 2.weeks)
    end

    it "properly calculates hours until" do
      expect(build(:event, start: nil).hours_until).to be_nil
      expect(build(:event, start: 1.hour.from_now).hours_until).to eq 1
      expect(build(:event, start: 1.day.from_now).hours_until).to eq 24
    end

  end

  it "responds properly to awaiting_approval? method" do
    c = create :coordinator
    expect(create(:event, status: :proposed, coordinator: c).awaiting_approval?).to be_true
    expect(create(:event, status: :approved, coordinator: c).awaiting_approval?).to be_false
    expect(create(:past_event, status: :proposed, coordinator: c).awaiting_approval?).to be_false
    expect(create(:event, status: :proposed, coordinator: nil).awaiting_approval?).to be_false
    expect(create(:event, status: :proposed, coordinator: c, start: nil, name: 'foo').awaiting_approval?).to be_false
  end

  context "users" do

    context "participatable_by?" do

      it "can join an event if there is nothing preventing it" do
        u = create :participant
        e = create :participatable_event
        expect(e.participatable_by? u).to be_true
      end

      it "cannot be joined if in the past" do
        u = create :participant
        e = create :participatable_past_event
        expect(e.participatable_by? u).to be_false
      end

      it "cannot be joined by non-participants" do
        u = create :coordinator
        e = create :participatable_event
        expect(e.participatable_by? u).to be_false
      end

      it "cannot be joined by someone who is already coordinating it" do
        u = create :coordinator
        u.roles.create name: :participant
        e = create :event, coordinator: u
        expect(e.participatable_by? u).to be_false
      end

      it "cannot be joined if there is no coordinator" do
        u = create :participant
        e = create :participatable_event, coordinator: nil
        expect(e.participatable_by? u).to be_false
      end

      it "cannot be joined if it has no dates" do
        u = create :participant
        e = create :participatable_event, start: nil, name: 'foo'
        expect(e.participatable_by? u).to be_false
      end

      it "cannot be joined if it has been cancelled" do
        u = create :participant
        e = create :participatable_event, status: :cancelled
        expect(e.participatable_by? u).to be_false
      end

      # todo: test that not participatable when a user has been denied for the event
      # denied feature not yet implemented

    end

    it "adds a participant" do
      e = create :participatable_event
      p = create :participant
      e.attend p
      expect(e.event_users.count).to eq 1
      eu = e.event_users.first
      expect(eu.user).to eq p
      expect(eu.status).to eq 'attending'
    end

    it "adds a participant to the waitlist" do
      e = create :participatable_event, max: 1
      e.attend create :participant
      p = create :participant
      e.attend p
      expect(e.event_users.length).to eq 2
      eu = e.event_users.last
      expect(eu.user).to eq p
      expect(eu.status).to eq 'waitlisted'
    end

    it "cancels participation" do
      e = create :participatable_event
      p = create :participant
      e.attend p
      e.unattend p
      expect(e.event_users.count).to eq 1
      eu = e.event_users.first
      expect(eu.user).to eq p
      expect(eu.status).to eq 'cancelled'
    end

    it "withdraws from waitlist" do
      e = create :participatable_event, max: 1
      e.attend create :participant
      p = create :participant
      e.attend p
      e.unattend p
      expect(e.event_users.count).to eq 2
      eu = e.event_users.last
      expect(eu.user).to eq p
      expect(eu.status).to eq 'withdrawn'
    end

    context "invitations" do

      it "has a maximum number of invitees of 50" do
        expect(Event.max_invitable).to eq 50
      end

      it "suggests number of invitations for a participtable event" do
        create :participant
        expect(build(:participatable_event).suggested_invitations).to be > 0
      end

      it "suggests zero invitations for a non-participtable event" do
        create :participant
        expect(build(:participatable_event, status: :proposed).suggested_invitations).to eq 0
        expect(build(:participatable_event, start: 1.month.ago).suggested_invitations).to eq 0
      end

      it "suggests zero invitations for full events" do
        create :participant
        e = create :participatable_event, max: 1
        e.attend create :participant
        expect(e.suggested_invitations).to eq 0
      end

      it "has invitable participants" do
        participant = create :participant
        e = create :participatable_event
        expect(e.invitable_participants).to include participant
      end

      it "excludes event coordinator from invitable participants" do
        c = create :coordinator
        c.roles.create name: :participant
        participant = create :participant
        e = create :participatable_event, coordinator: c
        expect(e.invitable_participants).to include participant
        expect(e.invitable_participants).not_to include c
      end

      it "excludes existing invitees and attendees from invitable participants" do
        e = create :participatable_event
        attending = create :participant
        e.attend attending
        invited = create :participant
        e.event_users.create user: invited, status: :invited
        p3 = create :participant
        p4 = create :participant
        invitable = e.invitable_participants
        expect(invitable).to include p3
        expect(invitable).to include p4
        expect(invitable).not_to include attending
        expect(invitable).not_to include invited
      end

      it "has invitable participants for geocoded events, closest first" do
        e = create :participatable_event, lat: 50, lng: 50
        near = create :participant, lat: 51, lng: 51
        far = create :participant, lat: 60, lng: 60
        invitable = e.invitable_participants
        expect(invitable.index near).to be < invitable.index(far)
      end

      it "says an event is invitable when nobody has been invited yet" do
        create :participant
        expect(create(:participatable_event).invitable?).to be_true
      end

      it "says an event is not invitable when an event is past" do
        create :participant
        expect(create(:participatable_past_event).invitable?).to be_false
      end

      it "says an event is not invitable when someone has been invited already" do
        create :participant
        e = create :participatable_event
        e.event_users.create user: create(:participant), status: :invited
        expect(e.invitable?).to be_false
      end

      it "says an event is not invitable when someone is already attending" do
        create :participant
        e = create :participatable_event
        e.attend create :participant
        expect(e.invitable?).to be_false
      end

      it "says an event is not invitable when there is nobody to invite" do
        User.participants.destroy_all # todo: should be handled by database cleaner...
        expect(create(:participatable_event).invitable?).to be_false
      end

    end

    context "number of participants/spots" do

      it "returns the number of participants needed when there is no min" do
        e = create :participatable_event, min: 0
        expect(e.participants_needed).to eq 0
      end

      it "returns the number of participants needed when there is a min" do
        e = create :participatable_event, min: 1
        expect(e.participants_needed).to eq 1
        e.attend create :participant
        expect(e.participants_needed).to eq 0
      end

      it "returns the number of remaining spots when there is no max" do
        e = create :participatable_event, max: nil
        expect(e.remaining_spots).to be_true
      end

      it "returns the number of remaining spots when there is a max" do
        e = create :participatable_event, max: 1
        expect(e.remaining_spots).to eq 1
        e.attend create :participant
        expect(e.remaining_spots).to eq 0
      end

      it "returns whether an event is full when there is no max" do
        e = create :participatable_event, max: nil
        expect(e.full?).to be_false
        e.attend create :participant
        expect(e.full?).to be_false
      end

      it "returns whether an event is full when there is a max" do
        e = create :participatable_event, max: 1
        expect(e.full?).to be_false
        e.attend create :participant
        expect(e.full?).to be_true
      end

    end

    context "list" do

      it "has an list of participants" do
        e = create :participatable_event
        expect(e.participants.length).to eq 0
        participant = create :participant
        e.attend participant
        expect(e.participants.reload).to eq [participant]
      end

      it "has a list of waitlisted users" do
        e = create :participatable_event, max: 1
        e.attend create :participant
        expect(e.waitlisted.count).to eq 0
        participant = create :participant
        e.attend participant
        expect(e.waitlisted).to eq [participant]
      end

      it "lists coordinator as user when there are no participants" do
        coordinator = create :coordinator
        e = create :participatable_event, coordinator: coordinator
        expect(e.users).to eq [coordinator]
      end

      it "lists coordinator and participants as users" do
        e = create :participatable_event, coordinator: create(:coordinator)
        participant = create :participant
        e.attend participant
        expect(e.users.length).to eq 2
        expect(e.users).to include participant
      end

    end

    context "waitlist" do

      it "adds participants from the waitlist, in the correct order" do
        e = create :participatable_event, max: 1
        participant = create :participant
        # artificially place two people on the waiting list even though they could just be attending
        e.event_users.create user: participant, status: EventUser.statuses[:waitlisted]
        e.event_users.create user: create(:participant), status: EventUser.statuses[:waitlisted]
        expect(e.participants.length).to eq 0
        e.add_from_waitlist
        expect(e.participants.reload).to eq [participant]
        expect(last_email.subject).to match 'are attending'
        expect(last_email.bcc).to eq [participant.email]
      end

      it "does not add participants from the waitlist for cancelled events" do
        e = create :participatable_event
        participant = create :participant
        # artificially place someone on the waiting list even though they could just be attending
        e.event_users.create user: participant, status: EventUser.statuses[:waitlisted]
        e.status = :cancelled
        e.add_from_waitlist
        expect(e.participants.reload.length).to eq 0
      end

      it "does not add participants from the waitlist for past events" do
        e = create :participatable_event
        participant = create :participant
        # artificially place someone on the waiting list even though they could just be attending
        e.event_users.create user: participant, status: EventUser.statuses[:waitlisted]
        e.start = 1.month.ago
        e.finish = 1.week.ago
        e.add_from_waitlist
        expect(e.participants.reload.length).to eq 0
      end

      it "adds participants from the waitlist when increasing the max" do
        e = create :participatable_event, max: 1
        p1 = create :participant
        e.attend p1
        p2 = create :participant
        e.attend p2
        expect(e.participants.reload).to eq [p1]
        e.update max: 100
        expect(e.participants.reload.length).to eq 2
      end

      it "adds participants from the waitlist when eliminiating the max" do
        e = create :participatable_event, max: 1
        p1 = create :participant
        e.attend p1
        p2 = create :participant
        e.attend p2
        expect(e.participants.reload).to eq [p1]
        e.update max: nil
        expect(e.participants.reload.length).to eq 2
      end

      it "removes participants to the waitlist when adding a max" do
        e = create :participatable_event
        p1 = create :participant
        e.attend p1
        p2 = create :participant
        e.attend p2
        expect(e.participants.reload.length).to eq 2
        e.update max: 1
        expect(e.participants.reload).to eq [p1]
        expect(e.waitlisted).to eq [p2]
      end

      it "removes participants to the waitlist when decreasing the max" do
        e = create :participatable_event, max: 2
        p1 = create :participant
        e.attend p1
        p2 = create :participant
        e.attend p2
        expect(e.participants.reload.length).to eq 2
        e.update max: 1
        expect(e.participants.reload).to eq [p1]
        expect(e.waitlisted).to eq [p2]
      end

      it "does not change the participants when not changing the max" do
        e = create :participatable_event, max: 1, name: 'foo'
        p1 = create :participant
        e.attend p1
        e.attend create :participant
        e.update name: 'bar'
        expect(e.participants.reload).to eq [p1]
      end

      it "does not change the participants when changing the max for a cancelled event" do
        e = create :participatable_event, max: 1, name: 'foo'
        p1 = create :participant
        e.attend p1
        e.attend create :participant
        e.update status: :cancelled
        e.update max: :nil
        expect(e.participants.reload).to eq [p1]
      end

    end

  end

  context "multiple events" do

    before :each do
      # todo: figure out why database cleaner isn't handling this
      Event.destroy_all
    end

    it "orders by soonest first" do
      event1 = create :event
      event2 = create :past_event
      event3 = create :event, start: event1.start + 1.hour
      events = Event.all
      expect(events.first).to eq event2
      expect(events.last).to eq event3
    end

    it "lists past events only, ordered by most recent first" do
      event1 = create :event
      event2 = create :past_event
      event3 = create :past_event, start: event2.start - 1.hour, finish: event2.finish - 1.hour # farther in the past than event2
      expect(Event.past).to eq [event2, event3]
    end

    it "lists only events which are not over" do
      event1 = create :event
      event2 = create :past_event
      event3 = create :event, start: event1.start + 1.hour
      events = Event.not_past
      expect(events.length).to eq 2
      expect(events).not_to include event2
    end

    it "lists only events not attended by a user" do
      c = create :coordinator
      participant = create :participant
      not_involved = create :participatable_event, coordinator: c
      attending = create :participatable_event, coordinator: c
      attending.attend participant
      invited = create :participatable_event, coordinator: c
      invited.event_users.create user: participant, status: :invited
      cancelled = create :participatable_event, coordinator: c
      cancelled.attend participant
      cancelled.unattend participant
      events = Event.not_attended_by participant
      expect(events.length).to eq 3
      expect(events).to include not_involved
      expect(events).to include invited
      expect(events).to include cancelled
    end

    it "lists events without a coordinator" do
      c = create :coordinator
      create :event, coordinator: c
      event2 = create :event, coordinator: nil
      events = Event.coordinatorless
      expect(events.length).to eq 1
      expect(events.first).to eq event2
    end

    it "lists events without dates" do
      create :event
      e = create :event, start: nil, name: 'foo'
      events = Event.dateless
      expect(events.length).to eq 1
      expect(events.first).to eq e
    end

    it "list events that can have participants" do
      e = create :participatable_event
      create :event, coordinator: nil
      events = Event.participatable
      expect(events.length).to eq 1
      expect(events.first).to eq e
    end

    it "lists events within a given month" do
      create :event, start: '2013-10-01'
      nov1 = create :event, start: '2013-11-01'
      nov2 = create :event, start: '2013-11-02'
      dec = create :event, start: '2013-12-01'
      jan = create :event, start: '2014-01-01'
      create :event, start: '2014-02-01'
      events_n = Event.in_month(2013, 11)
      events_d = Event.in_month(2013, 12)
      events_j = Event.in_month(2014, 1)
      expect(events_n.length).to eq 2
      expect(events_n).to include nov1
      expect(events_n).to include nov2
      expect(events_d).to eq [dec]
      expect(events_j).to eq [jan]
    end

    it "lists events awaiting approval" do
      c = create :coordinator
      e1 = create :event, status: :proposed, coordinator: c
      e2 = create :event, status: :proposed, coordinator: c
      e_approved = create :event, status: :approved, coordinator: c
      e_past = create :past_event, status: :proposed, coordinator: c
      e_no_coordinator = create :event, status: :proposed, coordinator: nil
      e_no_date = create :event, status: :proposed, coordinator: c, start: nil, name: 'foo'
      events = Event.awaiting_approval
      expect(events.length).to eq 2
      expect(events).to include e1
      expect(events).to include e2
    end

    it "lists events which will begin in two days" do # used for sending reminders
      c = create :coordinator
      now = Time.zone.now
      early  = create :participatable_event, start: now , coordinator: c
      late = create :participatable_event, start: now + 5.days, coordinator: c
      in_day = create :participatable_event, start: now + 2.days, coordinator: c
      in_day_proposed = create :participatable_event, start: now + 2.days, status: :proposed, coordinator: c
      expect(Event.will_happen_in_two_days).to eq [in_day]
    end

  end

end