require 'spec_helper'

describe "Event Attendance" do

  include Warden::Test::Helpers
  before :each do
    @admin = create :admin
    @participant = create :participant
  end
  after :each do
    Warden.test_reset!
  end

  it "joins an event" do
    login_as @participant
    e = create :participatable_event
    visit event_path(e)
    click_link 'Join'
    expect(current_path).to eq event_path(e)
    expect(page).to have_content @participant.display_name
  end

  it "sends a confirmation email on joining an event" do
    login_as @participant
    e = create :participatable_event
    visit event_path e
    expect { click_link 'Join' }.to change{ActionMailer::Base.deliveries.size}.by 1
    expect(last_email.to).to eq [@participant.email]
  end

  it "only allows participants to join events" do
    login_as @admin
    e = create :participatable_event
    visit event_path e
    expect(page).not_to have_content 'Join'
  end

  it "cancels attending an event" do
    login_as @participant
    e = create :participatable_event
    e.event_users.create user: @participant
    visit event_path e
    click_link 'Cancel'
    expect(current_path).to eq event_path e
    expect(page).not_to have_content @participant.email
  end

  it "prevents joining a past event" do
    login_as @participant
    e = create :past_event
    visit event_path e
    expect(page).not_to have_content 'Join'
  end

  it "prevents cancelling attendance on a past event" do
    login_as @participant
    e = create :participatable_past_event
    e.event_users.create user: @participant
    visit event_path e
    expect(page).not_to have_content 'Cancel'
  end

end