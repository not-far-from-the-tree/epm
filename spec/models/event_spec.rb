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
      expect(create(:event, description: " \n").description).to be_nil
    end

  end

  it "is invalid without a start" do
    expect(build(:event, start: nil)).not_to be_valid
  end

  it "is invalid without a finish" do
    expect(build(:event, finish: nil)).not_to be_valid
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

  context "attendable_by?" do

    it "can join an event if there is nothing preventing it" do
      u = create :participant
      e = create :event
      expect(e.attendable_by? u).to be_true
    end

    it "cannot be joined if in the past" do
      u = create :participant
      e = create :past_event
      expect(e.attendable_by? u).to be_false
    end

    it "cannot be joined by non-participants" do
      u = create :coordinator
      e = create :event
      expect(e.attendable_by? u).to be_false
    end

    it "cannot be joined by someone who is already coordinating it" do
      u = create :coordinator
      u.roles.create name: :participant
      e = create :event, coordinator: u
      expect(e.attendable_by? u).to be_false
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
      event1 = create :event
      event2 = create :event
      user = create :user
      event2.event_users.create user: user
      events = Event.not_attended_by user
      expect(events.length).to eq 1
      expect(events.first).to eq event1
    end

  end

end