require 'spec_helper'

describe "Users" do

  describe "Signs up a new user" do

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
      expect(ActionMailer::Base.deliveries.last.to).to eq [User.last.email]
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

  describe "Fails to sign up an invalid user" do

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

end