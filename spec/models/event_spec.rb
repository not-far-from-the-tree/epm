require 'spec_helper'

describe Event do

  [:name, :description, :start, :finish, :participants].each do |field|
    it "has #{field}" do
      expect(create(:event)).to respond_to field
    end
  end

  it "has a display name" do
    expect(create(:event).display_name).not_to be_blank
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
    expect(create(:event).past?).to eq false
    expect(create(:past_event).past?).to eq true
  end

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