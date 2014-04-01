require 'spec_helper'

describe Role do

  it "has a valid factory" do
    expect(create(:participant_role)).to be_valid
  end

  it "is invalid without a name" do
    expect(build(:participant_role, name: nil)).not_to be_valid
  end

  it "does not allow duplicates" do
    u = create :user, no_roles: true
    u.roles.create name: :participant
    expect(u.roles.build(name: :participant)).not_to be_valid
  end

  it "prevents deleting admin role when there are no other admins" do
    User.delete_all # todo: database cleaner should handle this but apparently not
    admin = create :admin_role
    expect(admin.destroy).to be_false
  end

end