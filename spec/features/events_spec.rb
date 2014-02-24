require 'spec_helper'

describe "Events" do

  # this is duplicated on events_spec.rb
  include Warden::Test::Helpers # see users_spec.rb for comments on this and related code
  before :all do
    @admin = create :admin
    @participant = create :participant
  end
  after :each do
    Warden.test_reset!
  end

  describe "CRUD" do

    it "creates an event" do
      login_as @admin
      visit root_path
      click_link 'Add New Event'
      expect{
        # leave default datetimes (for now...)
        click_button 'Create Event'
      }.to change{Event.count}.by 1
      expect(current_path).to eq event_path(Event.last)
    end

    it "prevents creating an event without permission" do
      login_as @participant
      visit root_path
      expect(page).not_to have_content 'Add New Event'
      visit new_event_path
      expect(page).to have_content 'Sorry'
    end

    it "views an event" do
      login_as @admin
      e = create :event
      visit root_path
      within '#upcoming ol' do
        all(:css, 'a').last.click
      end
      expect(current_path).to eq event_path(e)
    end

    it "updates an event" do
      login_as @admin
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

    it "prevents updating an event without permission" do
      login_as @participant
      e = create :event
      visit event_path(e)
      expect(page).not_to have_content 'Edit'
      visit edit_event_path(e)
      expect(page).to have_content 'Sorry'
    end

    it "deletes an event" do
      login_as @admin
      e = create :event
      visit event_path(e)
      expect{ click_link 'Delete' }.to change{Event.count}.by -1
      expect(current_path).to eq events_path
      expect(page).to have_content 'deleted'
    end

    it "prevents deleting an event without permission" do
      login_as @participant
      e = create :event
      visit event_path(e)
      expect(page).not_to have_content 'Delete'
    end

  end

  describe "attendance" do

    it "joins an event" do
      login_as @participant
      e = create :event
      visit event_path(e)
      expect { click_link 'Join' }.to change{e.participants.count}.by 1
      expect(current_path).to eq event_path(e)
      expect(page).to have_content @participant.email
    end

    it "only allows participants to join events" do
      login_as @admin
      e = create :event
      visit event_path(e)
      expect(page).not_to have_content 'Join'
    end

    it "cancels attending an event" do
      login_as @participant
      e = create :event
      e.event_users.create user: @participant
      visit event_path(e)
      expect { click_link 'Cancel' }.to change{e.participants.count}.by -1
      expect(current_path).to eq event_path(e)
      expect(page).not_to have_content @participant.email
    end

    it "prevents joining a past event" do
      login_as @participant
      e = create :past_event
      visit event_path(e)
      expect(page).not_to have_content 'Join'
    end

    it "prevents cancelling attendance on a past event" do
      login_as @participant
      e = create :past_event
      e.event_users.create user: @participant
      visit event_path(e)
      expect(page).not_to have_content 'Cancel'
    end

  end

end