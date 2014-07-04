require 'spec_helper'

describe "Event Attendance" do

  include Warden::Test::Helpers
  before :each do
    @admin = create :admin
    @participant = create :participant
    Event.destroy_all
  end
  after :each do
    Warden.test_reset!
  end

  it "describes the coordinator as attending" do
    e = create :participatable_event
    login_as e.coordinator
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You are attending'
      expect(all('button').length).to eq 0
    end
    visit root_path
    within '#coordinating' do
      expect(page).to have_link e.display_name
    end
  end

  it "does not describes a coordinator as attending when they are not on this event" do
    e = create :participatable_event
    login_as create :coordinator
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You are not attending'
      expect(all('button').length).to eq 0
    end
  end

  it "joins an event" do
    e = create :participatable_event
    login_as @participant
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You are not attending'
      expect(all('button').length).to eq 1
      click_button 'Attend'
    end
    expect(current_path).to eq event_path e
    expect(page).to have_content 'You are attending'
    visit root_path
    within '#attending' do
      expect(page).to have_link e.display_name
    end
  end

  it "sends a confirmation email on joining an event" do
    e = create :participatable_event
    login_as @participant
    visit event_path e
    expect { click_button 'Attend' }.to change{ActionMailer::Base.deliveries.size}.by 1
    expect(last_email.bcc).to eq [@participant.email]
  end

  it "does not allow admins to attend events" do
    e = create :participatable_event
    login_as @admin
    visit event_path e
    expect(page).not_to have_button 'Attend'
  end

  it "does not allow coordinators to participate in events" do
    e = create :participatable_event
    login_as create :coordinator
    visit event_path e
    expect(page).not_to have_button 'Attend'
  end

  it "cancels attending an event" do
    e = create :participatable_event
    e.attend @participant
    login_as @participant
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You are attending'
      expect(all('button').length).to eq 1
      click_button 'Cancel'
    end
    expect(current_path).to eq event_path e
    expect(page).to have_content 'You are not attending'
    expect(page).not_to have_link @participant.email
    visit root_path
    expect(all('#attending').length).to eq 0
  end

  it "prevents joining a past event" do
    e = create :participatable_past_event
    login_as @participant
    visit event_path e
    expect(page).to have_content 'You did not attend'
    within '#rsvp' do
      expect(all('button').length).to eq 0
    end
  end

  it "prevents cancelling attendance on a past event" do
    e = create :participatable_event
    e.attend @participant
    e.update(start: 1.month.ago, duration: 1.hour)
    login_as @participant
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You attended'
      expect(all('button').length).to eq 0
    end
  end

  it "does not allow participants to view who is attending an event" do
    e = create :participatable_event
    login_as @participant
    visit event_path e
    expect(page).not_to have_link 'Who'
    visit who_event_path e
    expect(current_path).not_to eq who_event_path e
    expect(page).to have_content 'Sorry'
  end

  context "waitlist" do

    it "joins an event waitlist" do
      e = create :participatable_event, max: 1
      e.attend create :participant
      login_as @participant
      visit event_path e
      within '#rsvp' do
        expect(page).to have_content 'You are not attending'
        expect(all('button').length).to eq 1
        click_button 'Add To Waitlist'
      end
      expect(current_path).to eq event_path e
      expect(page).to have_content 'You are on the waitlist'
      within 'header' do
        click_link 'Events'
      end
      within '#may_be_attending' do
        expect(page).to have_link e.display_name
      end
    end

    it "removes oneself from a waitlist" do
      e = create :participatable_event, max: 1
      e.attend create :participant
      e.attend @participant
      login_as @participant
      visit event_path e
      within '#rsvp' do
        expect(page).to have_content 'You are on the waitlist'
        expect(all('button').length).to eq 1
        click_button 'Withdraw Request'
      end
      expect(current_path).to eq event_path e
      expect(page).to have_content 'You are not attending'
      click_link 'My Profile'
      visit root_path
      expect(all('#may_be_attending').length).to eq 0
    end

    it "adds users on a waitlist when a participant cancels" do
      e = create :participatable_event, max: 1
      will_cancel = create :participant, fname: 'Whoever', lname: 'Lastylast'
      e.attend will_cancel
      will_attend = create :participant
      eu = e.attend will_attend # gets onto waitlist
      expect(eu.waitlisted?).to be_true
      login_as will_cancel
      visit event_path e
      within '#rsvp' do
        click_button 'Cancel'
      end
      expect(last_email.bcc).to eq [will_attend.email]
      expect(last_email.subject).to match 'Attending'
      logout
      login_as will_attend
      visit root_path
      within '#attending' do
        expect(page).to have_link e.display_name
      end
    end

    it "removes participants when the max is decreased" do
      e = create :participatable_event, max: 2
      p1 = create :participant, fname: 'Whoever', lname: 'Lastylast'
      e.attend p1
      p2 = create :participant, fname: 'Joeyjoejoe', lname: 'Shebeda'
      e.attend p2
      login_as @admin
      visit edit_event_path e
      fill_in 'Max', with: 1
      click_button 'Save & Notify'
      click_link 'Who'
      within '#participants' do
        expect(page).to have_link p1.display_name
        expect(page).not_to have_link p2.display_name
      end
      expect(last_email.subject).to match 'no longer attending'
      expect(last_email.bcc).to eq [p2.email]
    end

  end

  context "invitations" do

    it "auto invites participants upon approving an event which is ready for them, one accepts and one declines" do
      w = create :ward
      p1 = create :participant
      p1.user_wards.create ward: w
      p2 = create :participant
      p2.user_wards.create ward: w
      e = create :participatable_event, ward: w, status: :proposed
      login_as @admin
      visit event_path e
      click_link 'Approve'
      expect(page).to have_content 'Invitations will be sent'
      click_link 'Who'
      expect(page).to have_content '2 Not yet sent'

      run_task 'send_invitations'
      visit who_event_path e
      expect(page).not_to have_content '2 Not yet sent'
      expect(page).to have_content '2 Awaiting a response'

      login_as p1
      visit root_path
      within '#recommended' do
        click_link e.display_name
      end
      within '#rsvp' do
        expect(page).to have_content 'been invited'
        click_button 'Attend'
      end
      expect(current_path).to eq event_path e
      within "#rsvp" do
        expect(page).to have_content 'are attending'
      end
      logout
      login_as p2
      visit event_path e
      within '#rsvp' do
        expect(page).to have_content 'been invited'
        click_button 'Will Not Attend'
      end
      expect(current_path).to eq event_path e
      within "#rsvp" do
        expect(page).to have_content 'are not attending'
      end
      logout
      login_as @admin
      visit who_event_path e
      expect(page).to have_content '1 Declined'
    end

    it "sends five invitations at a time" do
      w = create :ward
      6.times do
        p = create :participant
        p.user_wards.create ward: w
      end
      e = create :participatable_event, ward: w, status: :proposed
      login_as @admin
      visit event_path e
      click_link 'Approve'
      expect(e.event_users.count).to eq 0
      expect(Invitation.all.count).to eq 6
      run_task 'send_invitations'
      expect(e.event_users.reload.count).to eq 5
      expect(Invitation.all.reload.count).to eq 1
    end

    it "does not send invitations to full events" do
      w = create :ward
      p = create :participant
      p.user_wards.create ward: w
      p2 = create :participant
      p2.user_wards.create ward: w
      e = create :participatable_event, ward: w, max: 1, status: :proposed
      login_as @admin
      visit event_path e
      click_link 'Approve'
      e.attend p
      run_task 'send_invitations'
      expect(e.event_users.count).to eq 1 # ie just 'attending' for p, no one with status 'invited' for p2
    end

  end

  context "taking attendance" do

    it "allows coordinator to take attendance" do
      e = create :participatable_past_event
      eu = e.event_users.create user: @participant, status: :attending
      p2 = create :participant, fname: 'Whoever', lname: 'Lastylast'
      eu2 = e.event_users.create user: p2, status: :attending
      login_as e.coordinator
      visit event_path e
      click_link 'Take Attendance'
      expect(page).not_to have_link 'Edit Attendance'
      expect(page).to have_link @participant.display_name
      expect(page).to have_link p2.display_name
      check("attendance_#{eu.id}")
      uncheck("attendance_#{eu2.id}")
      click_button 'Take Attendance'
      expect(current_path).to eq who_event_path e
      expect(page).to have_content 'Attendance taken'
      within '#participants' do
        expect(page).to have_link @participant.display_name
        expect(page).not_to have_link p2.display_name
      end
    end

    it "allows admin to take attendance" do
      e = create :participatable_past_event
      e.event_users.create user: @participant, status: :attending
      login_as @admin
      visit event_path e
      click_link 'Take Attendance'
      expect(page).to have_button 'Take Attendance'
    end

    it "does not allow taking attendance on a cancelled event" do
      e = create :participatable_past_event, status: :cancelled
      e.event_users.create user: @participant, status: :attending
      login_as e.coordinator
      visit who_event_path e
      expect(page).not_to have_button 'Take Attendance'
    end

    it "does not allow taking attendance when an event isn't over" do
      e = create :participatable_event, status: :cancelled
      e.attend @participant
      login_as e.coordinator
      visit who_event_path e
      expect(page).not_to have_button 'Take Attendance'
    end

    it "does not allow participants to take attendance" do
      e = create :participatable_past_event
      e.event_users.create user: @participant, status: :attending
      login_as @participant
      visit who_event_path e
      expect(page).not_to have_button 'Take Attendance'
    end

    it "allows coordinator to edit attendance to make corrections" do
      e = create :participatable_past_event
      eu = e.event_users.create user: @participant, status: :attended
      p2 = create :participant, fname: 'Whoever', lname: 'Lastylast'
      eu2 = e.event_users.create user: p2, status: :no_show
      login_as e.coordinator
      visit event_path e
      click_link 'Who'
      within '#participants' do
        expect(page).to have_link @participant.display_name
        expect(page).not_to have_link p2.display_name
      end
      expect(page).not_to have_button 'Take Attendance'
      click_link 'Edit Attendance'
      expect(current_path).to eq who_event_path e
      uncheck("attendance_#{eu.id}")
      check("attendance_#{eu2.id}")
      click_button 'Take Attendance'
      expect(current_path).to eq who_event_path e
      expect(page).to have_content 'Attendance taken'
      within '#participants' do
        expect(page).not_to have_link @participant.display_name
        expect(page).to have_link p2.display_name
      end
    end

  end

end