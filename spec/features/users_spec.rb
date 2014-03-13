require 'spec_helper'

describe "Users" do

  include Warden::Test::Helpers
  before :all do
    @participant = create :participant
    @coordinator = create :coordinator
    @admin = create :admin
  end
  after :each do
    Warden.test_reset!
  end

  context "user list" do

    it "allows admins to access user list" do
      login_as @admin
      visit root_path
      click_link 'Users'
      expect(current_path).to eq users_path
      expect(page).to have_content @admin.display_name
    end

    it "does not allow non-admins to access user list" do
      [@participant, @coordinator].each do |user|
        login_as user
        visit root_path
        expect(page).not_to have_content 'Users'
        visit users_path
        expect(current_path).not_to eq users_path
        expect(page).to have_content 'Sorry'
        logout
      end
    end

    it "shows user search results" do
      create :user, name: 'Joe', email: 'joe@example.com'
      create :user, name: 'Jack', email: 'jack@example.com'
      login_as @admin
      visit users_path
      fill_in 'q', with: 'joe'
      click_button 'Search'
      expect(current_path).to eq users_path
      expect(page).to have_content 'Joe'
      expect(page).not_to have_content 'Jack'
    end

    it "shows users with a particular role" do
      login_as @admin
      visit users_path
      select 'Admins', from: :role
      click_button 'Search'
      expect(find('option[selected]').text).to eq 'Admins'
      expect(page).to have_content @admin.display_name
      expect(page).not_to have_content @participant.display_name
      select 'Participants', from: :role
      click_button 'Search'
      expect(find('option[selected]').text).to eq 'Participants'
      expect(page).not_to have_content @admin.display_name
      expect(page).to have_content @participant.display_name
    end

    it "exports user list to csv" do
      login_as @admin
      visit users_path
      click_link 'Export'
      csv = CSV.parse(source) # using source as page has normalized the whitespace (thus having no newlines)
      expect(csv.length).to eq (User.count + 1)
      ['id', 'name', 'email', 'phone number', 'description', 'roles', 'events attended', 'joined'].each do |field|
        expect(csv.first).to include field
      end
      expect(page).to have_content @admin.email
    end

    it "shows 20 users per page" do
      25.times { create :user }
      login_as @admin
      visit users_path
      expect(all('.user').length).to eq 20
      expect(page).not_to have_link 'Prev'
      all('.next a').first.click
      expect(page).to have_link 'Prev'
      expect(page).not_to have_link 'Next'
      expect(all('.user').length).to eq (User.count - 20)
    end

  end

  context "profile" do

    before :each do
      login_as @participant
    end

    it "has a profile page" do
      visit root_path
      click_link 'My Profile'
      expect(current_path).to eq user_path @participant
      expect(page).to have_content @participant.display_name
    end

    it "edits own profile" do
      visit user_path(@participant)
      click_link 'Edit'
      expect(current_path).to eq edit_user_path @participant
      new_name = 'John Smith'
      fill_in 'Name', with: new_name
      click_button 'Save'
      expect(current_path).to eq user_path @participant
      expect(page).to have_content new_name
    end

    it "prevents editing another's profile" do
      other_user = create :user
      visit user_path(other_user)
      expect(page).not_to have_content 'Edit'
      visit edit_user_path(other_user)
      expect(current_path).to eq root_path
      expect(page).to have_content 'Sorry'
    end

  end

  context "roles" do

    it "allows an admin to add a role" do
      participant = create :participant # don't pollute @participant
      login_as @admin
      visit user_path participant
      select 'Coordinator', from: 'role_name'
      click_button 'Add'
      expect(current_path).to eq user_path participant
      expect(page).to have_content 'Role added'
      expect(participant.reload.has_role? :coordinator).to be_true
    end

    it "prevents non-admins from adding a role" do
      [@participant, @coordinator].each do |user|
        login_as user
        visit user_path @participant
        expect(page).not_to have_button 'Add'
        logout
      end
    end

    it "does not show role adding form if user has all roles" do
      user = create :participant
      user.roles.create name: :coordinator
      user.roles.create name: :admin
      login_as @admin
      visit user_path user
      expect(page).not_to have_button 'Add'
    end

    it "allows an admin to remove a role" do
      participant = create :participant # don't pollute @participant
      login_as @admin
      visit user_path participant
      click_link 'x' # user has only one role, so this is the right delete link
      expect(current_path).to eq user_path participant
      expect(page).to have_content 'Role removed'
      expect(participant.reload.has_role? :participant).to be_false
    end

    it "prevents non-admins from removing others' roles" do
      users = [@participant, @coordinator]
      users.each_with_index do |user, i|
        login_as user
        visit user_path users.reverse[i]
        expect(page).not_to have_button 'Add'
        logout
      end
    end

    it "allows removing own's own roles" do
      participant = create :participant
      login_as participant
      visit user_path participant
      click_link 'x' # user has only one role, so this is the right delete link
      expect(current_path).to eq user_path participant
      expect(page).to have_content 'Role removed'
      expect(participant.reload.has_role? :participant).to be_false
    end

  end

end