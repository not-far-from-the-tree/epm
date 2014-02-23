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

  # commented out due to this https://github.com/rails/rails/issues/14172
  # it "does not allow duplicates" do
  #   u = create :user, no_roles: true
  #   u.roles.create name: :participant
  #   expect(u.roles.build(name: :participant)).not_to be_valid
  # end

end