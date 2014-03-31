require 'spec_helper'

describe EventUser do

  it "is invalid without an event" do
    expect(build :event_user, event: nil).not_to be_valid
  end

  it "is invalid without a user" do
    expect(build :event_user, user: nil).not_to be_valid
  end

  it "is invalid without a status" do
    expect(build :event_user, status: nil).not_to be_valid
  end

  it "does not allow attending the same event more than once" do
    eu1 = create :event_user
    expect(build :event_user, user: eu1.user, event: eu1.event).not_to be_valid
  end

  it "does not allow attending a non-participatable event" do
    event = create :event # not participatable
    expect(build :event_user, event: event).not_to be_valid
  end

end