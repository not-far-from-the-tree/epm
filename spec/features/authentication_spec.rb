require 'spec_helper'

describe "Authentication" do

  describe "signs up a new user" do
    # consider merging some of these to improve speed as each hits the DB

    def sign_up
      visit new_user_registration_path
      fill_in 'Email', :with => Faker::Internet.email
      pass = Faker::Internet.password
      fill_in 'Password', :with => pass
      fill_in 'Password confirmation', :with => pass
      click_button 'Sign up'
    end

    it "creates a new user" do
      expect{ sign_up }.to change{User.count}.by 1
    end

    it "sends a confirmation email" do
      expect{ sign_up }.to change{ActionMailer::Base.deliveries.size}.by 1
      expect(last_email.to).to eq [User.last.email]
      expect(last_email.from).to eq ['no-reply@example.com']
    end

    it "logs them in" do
      sign_up
      expect(page).to have_content 'signed up successfully'
      expect(page).to have_content 'Log out'
    end

    it "returns them to the page they started from" do
      visit root_path
      sign_up
      expect(current_path).to eq root_path
    end

  end

  describe "fails to sign up an invalid user" do

    def bad_sign_up
      visit new_user_registration_path
      click_button 'Sign up'
    end

    it "does not create a new user" do
      expect{ bad_sign_up }.not_to change{User.count}
    end

    it "returns them to the sign up page" do
      bad_sign_up
      expect(current_path).to eq user_registration_path
    end

    it "displays an error message" do
      bad_sign_up
      expect(page).to have_content 'error'
    end

  end

  it "logs in a user" do
    pass = Faker::Internet.password
    u = FactoryGirl.create(:user, password: pass)
    visit new_user_session_path
    fill_in 'Email', with: u.email
    fill_in 'Password', with: pass
    click_button 'Sign in'
    expect(page).to have_content 'Log out'
  end

  it "fails to log in a user with bad credentials" do
    u = FactoryGirl.create :user
    visit new_user_session_path
    fill_in 'Email', with: u.email
    fill_in 'Password', with: Faker::Internet.password
    click_button 'Sign in'
    expect(page).to have_content 'Invalid'
  end

  it "sends a password reset email" do
    user = create(:user)
    visit new_user_session_path
    click_link 'Forgot your password?'
    fill_in 'Email', with: user.email
    expect { click_button 'Send' }.to change{ActionMailer::Base.deliveries.size}.by 1
    expect(last_email.to).to eq [user.email]
    expect(last_email.from).to eq ['no-reply@example.com']
    expect(page).to have_content 'You will receive'
  end

  it "does not send a password reset email to non-users" do
    visit new_user_session_path
    click_link 'Forgot your password?'
    fill_in 'Email', with: Faker::Internet.email
    expect { click_button 'Send' }.not_to change{ActionMailer::Base.deliveries.size}
    expect(page).to have_content 'error'
  end

  it "resends a confirmation email upon request" do
    user = create :user
    visit new_user_session_path
    click_link "Didn't receive confirmation instructions?"
    fill_in 'Email', with: user.email
    expect { click_button 'Resend' }.to change{ActionMailer::Base.deliveries.size}.by 1
    expect(last_email.to).to eq [user.email]
    expect(last_email.from).to eq ['no-reply@example.com']
    expect(page).to have_content 'You will receive'
  end

  it "does not resends a confirmation email to non-users" do
    visit new_user_session_path
    click_link "Didn't receive confirmation instructions?"
    fill_in 'Email', with: Faker::Internet.email
    expect { click_button 'Resend' }.not_to change{ActionMailer::Base.deliveries.size}
    expect(page).to have_content 'error'
  end

  context "when logged in" do

    include Warden::Test::Helpers
    before :all do
      @original_password = 'some_password'
      @user = create :user, password: @original_password
    end
    before :each do
      login_as @user
    end
    after :each do
      Warden.test_reset!
    end

    it "logs out" do
      login_as @user # supposedly we also need scope: :user but this doesn't affect test results
      visit root_path
      click_link 'Log out'
      expect(page).to have_content 'Sign in'
      Warden.test_reset! # this will be needed if/when using the warden test helpers in multiple tests
    end

    it "changes a password" do
      visit user_path @user
      click_link 'Change my password'
      new_password = 'new_password'
      fill_in 'Password', with: new_password
      fill_in 'Password confirmation', with: new_password
      fill_in 'Current password', with: @original_password
      click_button 'Change'
      expect(page).to have_content 'You updated your account successfully'
    end

  end

end