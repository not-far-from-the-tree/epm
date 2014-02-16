require 'spec_helper'

describe EventUser do

  it "has an event" do
    expect(create(:event_user)).to respond_to :event
  end

  it "has an event" do
    expect(create(:event_user)).to respond_to :user
  end

  it "is invalid without an event" do
    expect(build(:event_user, event: nil)).not_to be_valid
  end

  it "is invalid without a user" do
    expect(build(:event_user, user: nil)).not_to be_valid
  end

end