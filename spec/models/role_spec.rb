require 'spec_helper'

describe Role do

  it "has a valid factory" do
    expect(create(:participant_role)).to be_valid
  end

  it "is invalid without a user" do
    expect(build(:participant_role, user_id: nil)).not_to be_valid
  end

  it "is invalid without a name" do
    expect(build(:participant_role, name: nil)).not_to be_valid
  end

end