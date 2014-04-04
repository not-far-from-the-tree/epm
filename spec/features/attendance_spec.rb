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
      expect(all("input[type='submit']").length).to eq 0
    end
  end

  it "does not describes a coordinator as attending when they are not on this event" do
    e = create :participatable_event
    login_as create :coordinator
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You are not attending'
      expect(all("input[type='submit']").length).to eq 0
    end
  end

  it "joins an event" do
    e = create :participatable_event
    login_as @participant
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You are not attending'
      expect(all("input[type='submit']").length).to eq 1
      click_button 'Attend'
    end
    expect(current_path).to eq event_path e
    expect(page).to have_content 'You are attending'
    expect(page).to have_content @participant.display_name
    click_link 'My Profile'
    within '#upcoming' do
      expect(page).to have_link e.display_name
    end
  end

  it "sends a confirmation email on joining an event" do
    e = create :participatable_event
    login_as @participant
    visit event_path e
    expect { click_button 'Attend' }.to change{ActionMailer::Base.deliveries.size}.by 1
    expect(last_email.to).to eq [@participant.email]
  end

  it "only allows participants to join events" do
    login_as @admin
    e = create :participatable_event
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
      expect(all("input[type='submit']").length).to eq 1
      click_button 'Cancel'
    end
    expect(current_path).to eq event_path e
    expect(page).to have_content 'You are not attending'
    expect(page).not_to have_content @participant.email
    click_link 'My Profile'
    expect(page).not_to have_link e.display_name
  end

  it "prevents joining a past event" do
    e = create :participatable_past_event
    login_as @participant
    visit event_path e
    expect(page).to have_content 'You did not attend'
    within '#rsvp' do
      expect(all("input[type='submit']").length).to eq 0
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
      expect(all("input[type='submit']").length).to eq 0
    end
  end

  it "joins an event waitlist" do
    e = create :participatable_event, max: 1
    e.attend create :participant
    login_as @participant
    visit event_path e
    within '#rsvp' do
      expect(page).to have_content 'You are not attending'
      expect(all("input[type='submit']").length).to eq 1
      click_button 'Add To Waitlist'
    end
    expect(current_path).to eq event_path e
    expect(page).to have_content 'You are on the waitlist'
    click_link 'My Profile'
    within '#potential' do
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
      expect(all("input[type='submit']").length).to eq 1
      click_button 'Withdraw Request'
    end
    expect(current_path).to eq event_path e
    expect(page).to have_content 'You are not attending'
    click_link 'My Profile'
    expect(page).not_to have_link e.display_name
  end

end