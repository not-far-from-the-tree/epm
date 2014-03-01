require 'spec_helper'

describe Event do

  [:name, :description, :start, :finish, :participants, :coordinator].each do |field|
    it "has #{field}" do
      expect(create(:event)).to respond_to field
    end
  end

  it "has a display name" do
    expect(create(:event).display_name).not_to be_blank
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

  it "is invalid without a start" do
    expect(build :event, start: nil).not_to be_valid
  end

  it "is invalid without a finish or duration" do
    expect(build :event, duration: nil, finish: nil).not_to be_valid
  end

  it "is invalid with a zero duration" do
    expect(build :event, duration: 0).not_to be_valid
  end

  it "is invalid without a finish later than the start" do
    event = build :event
    event.finish = event.start - 1.day
    expect(event).not_to be_valid
  end

  it "responds properly to past? method" do
    expect(build(:event).past?).to be_false
    expect(build(:past_event).past?).to be_true
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

  end

  context "multiple events" do

    it "orders by date" do
      event1 = create :event
      event2 = create :past_event
      event3 = create :event, start: event1.start + 1.hour
      events = Event.all
      expect(events.first).to eq event2
      expect(events.last).to eq event3
    end

    it "lists past events only" do
      event1 = create :event
      event2 = create :past_event
      event3 = create :event, start: event1.start + 1.hour
      events = Event.past
      expect(events.length).to eq 1
      expect(events.first).to eq event2
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

    it "list events that can have participants" do
      e = create :participatable_event
      create :event, coordinator: nil
      events = Event.participatable
      expect(events.length).to eq 1
      expect(events.first).to eq e
    end

  end

end