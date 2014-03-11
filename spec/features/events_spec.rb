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
        click_button 'Save'
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
        click_button 'Save'
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
        click_button 'Save'
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

    context "updating" do

      # consider separating out testing that the duration select is showing the right value
      it "updates an event" do
        login_as @admin
        e = create :full_event
        visit event_path(e)
        click_link 'Edit'
        expect(find('#event_duration option[selected]').text).to have_content e.duration_hours
        new_event_name = 'new event name'
        fill_in 'Name', with: new_event_name
        click_button 'Save'
        expect(current_path).to eq event_path(e)
        expect(page).to have_content 'saved'
        expect(page).to have_content new_event_name
      end

      it "prevents updating an event without permission" do
        login_as @participant
        e = create :participatable_event
        visit event_path e
        expect(page).not_to have_content 'Edit'
        visit edit_event_path(e)
        expect(page).to have_content 'Sorry'
      end

      context "email notifications" do

        before :each do
          @coordinator = create :coordinator
          @participant = create :participant
          @e = create :participatable_event, coordinator: @coordinator
          @e.event_users.create user: @participant
        end

        it "emails attendees upon significantly changing an event" do
          login_as @admin
          visit edit_event_path @e
          fill_in 'Name', with: 'New name'
          expect{ click_button 'Save' }.to change{ActionMailer::Base.deliveries.size}.by 1
          expect(last_email.bcc.length).to eq 2
          expect(last_email.bcc).to include @coordinator.email
          expect(last_email.bcc).to include @participant.email
        end

        it "emails participants but not coordinator upon the coordinator significantly changing an event" do
          login_as @coordinator
          visit edit_event_path @e
          fill_in 'Name', with: 'New name'
          expect{ click_button 'Save' }.to change{ActionMailer::Base.deliveries.size}.by 1
          expect(last_email.bcc).to eq [@participant.email]
        end

        it "emails attendees but not coordinator upon significantly changing an event and also assigning a coordinator" do
          new_coordinator = create :coordinator
          login_as @admin
          visit edit_event_path @e
          fill_in 'Name', with: 'New name'
          select new_coordinator.display_name, from: 'Coordinator'
          ActionMailer::Base.deliveries.clear
          # expecting to send a notice to the new coordinator of the event
          # and also the notice to existing participants of changes
          # which should be the last email
          expect{ click_button 'Save' }.to change{ActionMailer::Base.deliveries.size}.by 2
          expect(last_email.bcc).to eq [@participant.email]
        end

        it "does not email attendees upon changing an event in a minor way" do
          login_as @admin
          visit edit_event_path @e
          select '', from: 'Coordinator'
          expect{ click_button 'Save' }.to change{ActionMailer::Base.deliveries.size}.by 0
        end

      end

    end

    context "deleting" do

      it "deletes an event" do
        login_as @admin
        e = create :event
        visit event_path e
        expect{ click_link 'Delete' }.to change{Event.count}.by -1
        expect(current_path).to eq events_path
        expect(page).to have_content 'deleted'
      end

      it "prevents participants from deleting an event" do
        login_as @participant
        e = create :event
        visit event_path e
        expect(page).not_to have_content 'Delete'
      end

      it "sends an email to coordinator and participants when an event is cancelled" do
        e = create :participatable_event
        participant = create :participant
        e.event_users.create user: participant
        login_as @admin
        visit event_path e
        expect{ click_link 'Delete' }.to change{ActionMailer::Base.deliveries.size}.by 1
        expect(last_email.bcc.length).to eq 2
        expect(last_email.bcc).to include e.coordinator.email
        expect(last_email.bcc).to include participant.email
      end

      it "sends an email to participants but not the coordinator when an event is cancelled by the coordinator" do
        coordinator = create :coordinator
        e = create :participatable_event, coordinator: coordinator
        participant = create :participant
        e.event_users.create user: participant
        login_as coordinator
        visit event_path e
        expect{ click_link 'Delete' }.to change{ActionMailer::Base.deliveries.size}.by 1
        expect(last_email.bcc.length).to eq 1
        expect(last_email.bcc.first).to eq participant.email
      end

      it "does not send an email when an event is cancelled that does not have a coordinator or participants" do
        e = create :event
        login_as @admin
        visit event_path e
        expect{ click_link 'Delete' }.to change{ActionMailer::Base.deliveries.size}.by 0
      end

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
        click_button 'Save'
        expect(current_path).to eq event_path(Event.order(:created_at).last)
        expect(page).to have_content @coordinator.display_name
      end

      describe "email notifications" do

        it "notifies a coordinator when a new event is assigned to them" do
          login_as @admin
          visit new_event_path
          fill_in 'Name', with: 'some event'
          select @coordinator.display_name, :from => 'Coordinator'
          expect{ click_button 'Save' }.to change{ActionMailer::Base.deliveries.size}.by 1
          expect(last_email.to.first).to match @coordinator.email
        end

        it "notifies a coordinator when an existing event is assigned to them" do
          e = create :event, coordinator: nil
          login_as @admin
          visit edit_event_path(e)
          select @coordinator.display_name, :from => 'Coordinator'
          expect{ click_button 'Save' }.to change{ActionMailer::Base.deliveries.size}.by 1
          expect(last_email.to.first).to match @coordinator.email
        end

        it "does not notify a coordinator when they assign an event to themselves" do
          e = create :event, coordinator: nil
          login_as @coordinator
          visit edit_event_path(e)
          select @coordinator.display_name, :from => 'Coordinator'
          expect{ click_button 'Save' }.to change{ActionMailer::Base.deliveries.size}.by 0
        end

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
        click_button 'Save'
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
        click_button 'Save'
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
        click_button 'Save'
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

    it "sends a confirmation email on joining an event" do
      login_as @participant
      e = create :participatable_event
      visit event_path(e)
      expect { click_link 'Join' }.to change{ActionMailer::Base.deliveries.size}.by 1
      expect(last_email.to).to eq [@participant.email]
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

  context "user and coordinator features" do

    it "lets admins see attendees' profiles" do
      login_as @admin
      e = create :participatable_event
      e.event_users.create user: @participant
      visit event_path(e)
      click_link @participant.display_name
      expect(current_path).to eq user_path(@participant)
    end

    it "does not let participants see attendees' profiles" do
      e = create :participatable_event
      e.event_users.create user: create(:participant)
      login_as @participant
      visit event_path(e)
      expect(all('#participants a').length).to eq 0
    end

    context "notes" do

      # the first test creates the note through the ui to test that, the others don't need to

      it "shows notes to admins" do
        login_as @admin
        visit new_event_path
        fill_in 'Name', with: 'Event name'
        fill_in 'Notes', with: 'Some note'
        click_button 'Save'
        expect(page).to have_content 'Some note'
      end

      it "shows notes to coordinator of an event" do
        e = create :participatable_event, notes: 'Some note'
        login_as e.coordinator
        visit event_path e
        expect(page).to have_content 'Some note'
      end

      it "does not show notes to coordinator not on an event" do
        e = create :event, notes: 'Some note'
        login_as create :coordinator
        visit event_path e
        expect(page).not_to have_content 'Some note'
      end

      it "does not show notes to participant" do
        e = create :participatable_event, notes: 'Some note'
        e.event_users.create user: create(:participant)
        login_as e.participants.first
        visit event_path e
        expect(page).not_to have_content 'Some note'
      end

    end

  end

end