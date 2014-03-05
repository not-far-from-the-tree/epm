require 'spec_helper'

describe "Events" do

  include Warden::Test::Helpers
  before :each do
    @admin = create :admin
    @participant = create :participant
  end
  after :each do
    Warden.test_reset!
  end

  describe "CRUD" do

    context "creating" do

      it "creates a dateless event" do
        login_as @admin
        visit root_path
        click_link 'Add New Event'
        e = build :full_event
        fill_in 'Name', with: e.name
        click_button 'Create Event'
        expect(current_path).to eq event_path Event.last
        expect(page).to have_content e.name
        expect(page).to have_content 'No date set'
      end

      it "creates an event with dates when js is disabled" do
        e = build :event
        login_as @admin
        visit new_event_path
        fill_in 'Date', with: e.start.to_date
        select (e.duration / 3600), from: 'For'
        click_button 'Create Event'
        expect(current_path).to eq event_path Event.last
        # expect(page).to have_content Event.humanize(e.start) # todo: figure out timezone issues causing this to fail
        expect(page).to have_content "#{e.duration_hours} hour"
        expect(page).not_to have_content 'No date set'
      end

      it "creates an event with dates when js is enabled", js: true do
        login_as @admin
        visit new_event_path
        e = build :event
        within '#datepicker' do
          click_link 29 # select date towards the end of the current month
        end
        select (e.duration / 3600), from: 'For'
        click_button 'Create Event'
        expect(current_path).to eq event_path Event.last
        # expect(page).to have_content Event.humanize(e.start) # todo: figure out timezone issues causing this to fail
        expect(page).to have_content "#{e.duration_hours} hour"
        expect(page).not_to have_content 'No date set'
      end

      it "prevents participants from creating events" do
        login_as @participant
        visit root_path
        expect(page).not_to have_content 'Add New Event'
        visit new_event_path
        expect(page).to have_content 'Sorry'
      end

      it "prevents coordinators from creating events" do
        login_as create :coordinator
        visit root_path
        expect(page).not_to have_content 'Add New Event'
        visit new_event_path
        expect(page).to have_content 'Sorry'
      end

    end

    it "views an event" do
      login_as @admin
      e = create :event
      visit root_path
      click_link e.display_name
      expect(current_path).to eq event_path e
    end

    # consider separating out testing that the duration select is showing the right value
    it "updates an event" do
      login_as @admin
      e = create :full_event
      visit event_path(e)
      click_link 'Edit'
      expect(find('#event_duration option[selected]').text).to have_content e.duration_hours
      new_event_name = 'new event name'
      fill_in 'Name', with: new_event_name
      click_button 'Update Event'
      expect(current_path).to eq event_path(e)
      expect(page).to have_content 'updated'
      expect(page).to have_content new_event_name
    end

    it "prevents updating an event without permission" do
      login_as @participant
      e = create :participatable_event
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

    it "prevents participants from deleting an event" do
      login_as @participant
      e = create :event
      visit event_path(e)
      expect(page).not_to have_content 'Delete'
    end

    context "coordinator" do

      before :each do
        @coordinator = create :coordinator
      end

      it "prevents coordinators from deleting an event with no coordinator" do
        login_as @coordinator
        visit event_path(create :event)
        expect(page).not_to have_content 'Delete'
      end

      it "prevents coordinators from deleting an event with another coordinator" do
        login_as @coordinator
        e = create :event, coordinator:(create :coordinator)
        visit event_path(e)
        expect(page).not_to have_content 'Delete'
      end

      it "allows a coordinator to delete their own event" do
        login_as @coordinator
        e = create :event, coordinator: @coordinator
        visit event_path(e)
        expect{ click_link 'Delete' }.to change{Event.count}.by -1
        expect(current_path).to eq events_path
        expect(page).to have_content 'deleted'
      end

      it "allows admin to set a coordinator" do
        login_as @admin
        visit new_event_path
        fill_in 'Name', with: 'some event'
        select @coordinator.display_name, :from => 'Coordinator'
        click_button 'Create Event'
        expect(current_path).to eq event_path(Event.order(:created_at).last)
        expect(page).to have_content @coordinator.display_name
      end

      it "allows coordinator to set an event's coordinator only to his/herself" do
        coordinator2 = create :coordinator
        e = create :event
        login_as @coordinator
        visit root_path
        within '#coordinatorless' do
          first('a').click
        end
        click_link 'Edit'
        expect(page).to have_select('Coordinator', :options => ['', @coordinator.display_name])
      end

      it "allows a coordinator to edit a coordinatorless event" do
        e = create :event
        login_as @coordinator
        visit root_path
        within '#coordinatorless' do
          first('a').click
        end
        click_link 'Edit'
        name = 'some name'
        fill_in 'Name', with: name
        click_button 'Update Event'
        expect(current_path).to eq event_path e
        expect(page).to have_content name
      end

      it "allows a coordinator to edit an event they are coordinating" do
        e = build :event
        e.coordinator = @coordinator
        e.save
        login_as @coordinator
        visit edit_event_path e
        name = 'some name'
        fill_in 'Name', with: name
        click_button 'Update Event'
        expect(current_path).to eq event_path e
        expect(page).to have_content name
      end

      it "allows coordinator to edit a dateless event" do
        e = create :event, coordinator: @coordinator, start: nil, name: 'foo'
        login_as @coordinator
        visit root_path
        within '#dateless' do
          first('a').click
        end
        click_link 'Edit'
        name = 'some name'
        fill_in 'Name', with: name
        click_button 'Update Event'
        expect(current_path).to eq event_path e
        expect(page).to have_content name
      end

      it "does not allow a coordinator to edit an event with another coordinator" do
        e = build :event
        e.coordinator = @coordinator
        e.save
        login_as create :coordinator
        visit event_path e
        expect(page).not_to have_content 'Edit'
        visit edit_event_path(e)
        expect(current_path).not_to eq edit_event_path(e)
        expect(page).to have_content 'Sorry'
      end

    end

  end

  describe "attendance" do

    it "joins an event" do
      login_as @participant
      e = create :participatable_event
      visit event_path(e)
      expect { click_link 'Join' }.to change{e.participants.count}.by 1
      expect(current_path).to eq event_path(e)
      expect(page).to have_content @participant.email
    end

    it "only allows participants to join events" do
      login_as @admin
      e = create :participatable_event
      visit event_path(e)
      expect(page).not_to have_content 'Join'
    end

    it "cancels attending an event" do
      login_as @participant
      e = create :participatable_event
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
      e = create :participatable_past_event
      e.event_users.create user: @participant
      visit event_path(e)
      expect(page).not_to have_content 'Cancel'
    end

  end

  context "listing events" do

    it "does not show non-participatable events to participants" do
      e = create :event, coordinator: nil
      login_as @participant
      visit root_path
      expect(page).not_to have_content 'with No Coordinator'
    end

    it "shows current and past events on their respective pages" do
      current = create :participatable_event
      past = create :participatable_past_event
      login_as @admin
      visit root_path
      expect(page).to have_content current.display_name
      expect(page).not_to have_content past.display_name
      click_link 'Past Events'
      expect(page).to have_content past.display_name
      expect(page).not_to have_content current.display_name
    end

  end

  it "lets people with permission see attendees' profiles" do
    login_as @admin
    e = create :participatable_event
    e.event_users.create user: @participant
    visit event_path(e)
    click_link @participant.display_name
    expect(current_path).to eq user_path(@participant)
  end

end