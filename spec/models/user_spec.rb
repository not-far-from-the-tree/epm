require 'spec_helper'

describe User do

  it "has a valid factory" do
    expect(create(:user)).to be_valid
  end

  it "is invalid without an email" do
    expect(build(:user, email: nil)).not_to be_valid
  end

  it "is invalid without a password" do
    expect(build(:user, password: nil)).not_to be_valid
  end

  it "is invalid with an overly short password" do
    expect(build(:user, password: "foo")).not_to be_valid
  end

  it "is invalid with an incorrect password confirmation" do
    expect(build(:user, password: "1234567", password_confirmation: "1234568")).not_to be_valid
  end

  it "does not allow multiple users with the same email, case insensitively" do
    user1 = build :user
    user1.email = user1.email.upcase
    user1.save
    expect(build(:user, email: user1.email.downcase)).not_to be_valid
  end

end
