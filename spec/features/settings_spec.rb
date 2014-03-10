require 'spec_helper'

describe "Settings" do

  include Warden::Test::Helpers
  after :each do
    Warden.test_reset!
  end

  context "access control" do

    [:participant, :coordinator].each do |role|
      it "does not allow access by #{role}" do
        login_as create role
        visit root_path
        expect(page).not_to have_content 'Settings'
        visit settings_path
        expect(current_path).not_to eq settings_path
        expect(page).to have_content 'Sorry'
      end
    end

    it "allows access by admin" do
      login_as create :admin
      visit root_path
      click_link 'Settings'
      expect(current_path).to eq settings_path
    end

  end

  context "as admin" do

    # this also tests that the default value works
    # and that after changing settings, you're back on the settings page
    it "changes the short site title" do
      login_as create :admin
      visit settings_path
      within 'header h1' do
        expect(page).to have_content 'EPM' # default short title
      end
      fill_in 'Site Title (short)', with: 'Foo'
      click_button 'Save'
      expect(current_path).to eq settings_path
      within 'header h1' do
        expect(page).to have_content 'Foo'
      end
    end

  end

end