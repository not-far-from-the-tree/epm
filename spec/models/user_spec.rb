require 'spec_helper'

describe User do

  context "validity" do

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

  [:name, :email, :description, :phone].each do |field|
    it "has #{field}" do
      expect(build :user).to respond_to field
    end
  end

  it "has a display name" do
    expect(build(:user).display_name).not_to be_blank
  end

  it "has an avatar which is a url" do
    expect(build(:user).avatar).to match URI::regexp(%w(http https))
  end

  # all fields should be stripped, this just tests two (excessive to check them all)
  context "normalizing attributes" do

    it "strips the name" do
      expect(create(:user, name: "  Joe\n").name).to eq 'Joe'
    end

    it "nullifies empty description" do
      expect(create(:user, description: " \n").description).to be_nil
    end

  end

  context "roles" do

    it "ensures the first user is an admin but others are participants" do
      User.destroy_all # todo: figure out why this is needed... should be handled by database cleaner
      expect(create(:user).roles.where(name: Role.names[:admin]).count).to eq 1
      expect(create(:user).roles.where(name: Role.names[:participant]).count).to eq 1
    end

    it "creates a user with the specified role" do
      role_name = :coordinator
      expect(create(:user, roles_attributes: [name: role_name]).roles.where(name: Role.names[role_name]).count).to eq 1
    end

  end

  context "multiple users" do

    before :each do
      User.destroy_all # todo: figure out why this is needed... should be handled by database cleaner
    end

    it "lists users according to role" do
      a = create :admin
      c = create :coordinator
      p1 = create :participant
      p1.roles.create name: :coordinator
      p2 = create :participant
      p3 = create :participant
      participants = User.participants
      expect(participants.length).to eq 3
      expect(participants).to include p1
      expect(participants).to include p2
      expect(participants).to include p3
      coordinators = User.coordinators
      expect(coordinators.length).to eq 2
      expect(coordinators).to include c
      expect(coordinators).to include p1
      admins = User.admins
      expect(admins.length).to eq 1
      expect(admins.first).to eq a
    end

    it "searches for users" do
      u1 = create :user, name: 'Joe Smith', email: 'joe_smith@example.com'
      u2 = create :user, name: 'Sally', email: 'sally_smith@example.com'
      u3 = create :user, name: 'Bob Dole', email: 'blabla@example.com'
      smiths = User.search 'smith' # checks that it looks in both name and email fields
      expect(smiths.length).to eq 2
      expect(smiths).to include u1
      expect(smiths).to include u2
      bobs = User.search 'bob' # checks for case sensitivity
      expect(bobs.length).to eq 1
      expect(bobs.first).to eq u3
      expect(User.search('Jack').length).to eq 0
    end

  end

  context "events" do

    it "lists events a user is participating in" do
      u = create :participant
      e1 = create :participatable_event
      e1.event_users.create user: u
      e2 = create :participatable_event
      e2.event_users.create user: u
      create :participatable_event # event 3, not participating
      expect(u.participating_events.length).to eq 2
    end

    it "lists events a user is coordinating" do
      u = create :coordinator
      create :event, coordinator: u
      create :event, coordinator: u
      create :event # event 3, not coordinating
      expect(u.coordinating_events.length).to eq 2
    end

    it "lists events a user is involved with" do
      u = create :coordinator
      create :participatable_event, coordinator: u
      u.roles.create name: :participant
      e1 = create :participatable_event
      e1.event_users.create user: u
      e2 = create :participatable_event
      e2.event_users.create user: u
      create :participatable_event # event 4, not coording or participating
      expect(u.events.length).to eq 3
    end

  end

end