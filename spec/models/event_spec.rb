require 'spec_helper'

describe Event do

  [:status, :name, :description, :notes, :start, :finish, :coordinator].each do |field|
    it "has #{field}" do
      expect(create(:event)).to respond_to field
    end
  end

  it "has a display name" do
    expect(create(:event).display_name).not_to be_blank
  end

  context "significant attributes" do

    it "has significant attributes" do
      [:name, :description, :start, :finish].each do |attr|
        expect(Event.significant_attributes).to include attr
      end
      [:coordinator_id, :fake_attribute].each do |attr|
        expect(Event.significant_attributes).not_to include attr
      end
    end

    it "is significantly changed when changing the start time" do
      e = create :event
      e.start = e.start - 1.hour
      expect(e.changed_significantly?).to be_true
    end

    it "is not significantly changed when changing the coordinator" do
      e = create :event
      e.coordinator = create :coordinator
      expect(e.changed_significantly?).to be_false
    end

  end

  context "users" do

    it "has an list of participants when there are none" do
      e = create :participatable_event
      expect(e.participants.length).to eq 0
    end

    it "has a list of participants when there are some" do
      e = create :participatable_event
      participant = create :participant
      e.event_users.create user: participant
      expect(e.participants).to eq [participant]
    end

    it "lists coordinator as user when there are no participants" do
      coordinator = create :coordinator
      e = create :participatable_event, coordinator: coordinator
      expect(e.users).to eq [coordinator]
    end

    it "lists coordinator and participants as users" do
      e = create :participatable_event, coordinator: create(:coordinator)
      participant = create :participant
      e.event_users.create user: participant
      expect(e.users.length).to eq 2
      expect(e.users).to include participant
    end

  end

  context "validity and normalization" do

    it "is invalid without a name, description, or start" do
      expect(build :event, start: nil, name: nil, description: nil).not_to be_valid
      expect(build :event, start: Time.zone.now, name: nil, description: nil).to be_valid
      expect(build :event, start: nil, name: 'some name', description: nil).to be_valid
      expect(build :event, start: nil, name: nil, description: 'some description').to be_valid
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

  end

  context "multiple events" do

    before :each do
      # argh gotta use db cleaner instead
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
      event1 = create :participatable_event
      event2 = create :participatable_event
      user = create :user
      event2.event_users.create user: user
      events = Event.not_attended_by user
      expect(events.length).to eq 1
      expect(events.first).to eq event1
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

  end

end