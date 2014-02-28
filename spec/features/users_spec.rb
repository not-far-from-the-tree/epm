require 'spec_helper'

describe "Users" do

  include Warden::Test::Helpers
  before :all do
    @participant = create :participant
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

    it "does not allow participants to access user list" do
      login_as @participant
      visit root_path
      expect(page).not_to have_content 'Users'
      visit users_path
      expect(current_path).not_to eq users_path
      expect(page).to have_content 'Sorry'
    end

    it "does not allow coordinators to access user list" do
      login_as create :coordinator
      visit root_path
      expect(page).not_to have_content 'Users'
      visit users_path
      expect(current_path).not_to eq users_path
      expect(page).to have_content 'Sorry'
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

    it "makes a user a coordinator" do
      login_as @admin
      visit user_path @participant
      expect{click_button 'Make coordinator'}.to change{@participant.roles.where(name: Role.names[:coordinator]).count}.by 1
      expect(current_path).to eq user_path @participant
      expect(page).to have_content 'is now a coordinator'
    end

    it "prevent non-admins from making a user a coordinator" do
      login_as @participant
      visit user_path @participant
      expect(page).not_to have_content 'Make coordinator'
    end

  end

end