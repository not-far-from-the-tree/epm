require 'spec_helper'

describe "Navigation" do

  include Warden::Test::Helpers
  before :all do
    @admin = create :admin
    @participant = create :participant
  end
  after :each do
    Warden.test_reset!
  end

  it "shows the right nav links for participants" do
    login_as @participant
    visit root_path
    within 'nav' do
      expect(page).to have_content 'Events'
      expect(page).to have_content 'My Profile'
      expect(page).not_to have_content 'Users'
    end
  end

  it "shows the right nav links for admins" do
    login_as @admin
    visit root_path
    within 'nav' do
      expect(page).to have_content 'Events'
      expect(page).to have_content 'My Profile'
      expect(page).to have_content 'Users'
    end
  end

  it "shows the right active nav link for events" do
    login_as @admin
    visit root_path
    expect(find('nav .active').text).to eq 'Events'
    visit new_event_path
    expect(find('nav .active').text).to eq 'Events'
    e = create :event
    visit event_path e
    expect(find('nav .active').text).to eq 'Events'
    visit edit_event_path e
    expect(find('nav .active').text).to eq 'Events'
  end

  it "shows the right active nav link for users" do
    login_as @admin
    visit users_path
    expect(find('nav .active').text).to eq 'Users'
    visit user_path @participant
    expect(find('nav .active').text).to eq 'Users'
  end

  it "shows the right active nav link for users" do
    login_as @admin
    visit user_path @admin
    expect(find('nav .active').text).to eq 'My Profile'
    visit edit_user_path @admin
    expect(find('nav .active').text).to eq 'My Profile'
  end

end