require 'spec_helper'

describe "Events" do

  include Warden::Test::Helpers # see users_spec.rb for comments on this and related code

  before :all do
    @user = create :user
  end
  before :each do
    login_as @user
  end
  after :each do
    Warden.test_reset!
  end

  describe "CRUD" do

    it "creates an event" do
      visit root_path
      click_link 'Add New Event'
      expect{
        # leave default datetimes (for now...)
        click_button 'Create Event'
      }.to change{Event.count}.by 1
      expect(current_path).to eq event_path(Event.last)
    end

    it "views an event" do
      e = create :event
      visit root_path
      # will need to replace the below with a selector that is more specific as to the event
      within 'ol' do
        all(:css, 'a').last.click
      end
      expect(current_path).to eq event_path(e)
    end

    it "updates an event" do
      e = create :event
      visit event_path(e)
      click_link 'Edit'
      next_year = DateTime.now.year + 1
      select next_year, from: 'event[start(1i)]'
      select next_year, from: 'event[finish(1i)]'
      click_button 'Update Event'
      expect(current_path).to eq event_path(e)
      expect(page).to have_content 'updated'
      expect(page).to have_content next_year
    end

    it "deletes an event" do
      e = create :event
      visit event_path(e)
      expect{ click_link 'Delete' }.to change{Event.count}.by -1
      expect(current_path).to eq events_path
      expect(page).to have_content 'deleted'
    end

  end

  describe "attendance" do

    it "joins an event" do
      e = create :event
      visit event_path(e)
      expect { click_link 'Join' }.to change{e.participants.count}.by 1
      expect(current_path).to eq event_path(e)
      expect(page).to have_content @user.email
    end

    it "cancels attending an event" do
      e = create :event
      e.event_users.create user: @user
      visit event_path(e)
      expect { click_link 'Cancel' }.to change{e.participants.count}.by -1
      expect(current_path).to eq event_path(e)
      expect(page).not_to have_content @user.email
    end

  end

end