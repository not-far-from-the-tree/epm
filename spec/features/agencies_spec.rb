require 'spec_helper'

describe "Agencies" do

  include Warden::Test::Helpers
  before :each do
    @admin = create :admin
    @participant = create :participant
  end
  after :each do
    Warden.test_reset!
  end

    context "creating" do
      context "as admin" do
        it "create an agency with title and description" do
          login_as @admin
          visit root_path
          click_link 'Agencies'
          click_link 'New Agency'
          es = build :full_agency
          fill_in 'Title', with: es.title
          fill_in 'Description', with: es.description
          click_button 'Create Agency'
          expect(current_path).to eq agency_path(Agency.last.id)
          expect(page).to have_content es.title
          expect(page).to have_content es.description
        end 

        it "create an agency with title but no description" do
          login_as @admin
          visit root_path
          click_link 'Agencies'
          click_link 'New Agency'
          es = build :full_agency
          fill_in 'Title', with: es.title
          click_button 'Create Agency'
          expect(current_path).to eq agency_path(Agency.last.id)
          expect(page).to have_content es.title
        end 

        it "try to create an agency with no title and no description" do
          login_as @admin
          visit root_path
          click_link 'Agencies'
          click_link 'New Agency'
          es = build :full_agency
          fill_in 'Title', with: ""
          fill_in 'Description', with: ""
          click_button 'Create Agency'
          expect(current_path).to eq agencies_path
          expect(page).to have_content "Title can't be blank"
        end 
      end
  end



  context "using" do
      context "as admin" do
        it "selects an agency" do
          login_as @admin
          visit root_path
          click_link 'Agencies'
          click_link 'New Agency'
          es = build :full_agency
          fill_in 'Title', with: es.title
          click_button 'Create Agency'
          visit root_path
          click_link 'Add New Event'
          expect(page).to have_select 'event[agency_id]'
          select es.title, :from => "event[agency_id]"
          e = build :full_event
          fill_in 'Name', with: e.name
          click_button 'Save'
          expect(page).to have_content es.title
        end 

      end
  end

  context "viewing" do
      context "as participant" do
        it "can't view agencies" do
          login_as @participant
          visit root_path
          expect(page).not_to have_content "Agencies"
        end
      end 

      context "as admin" do
        it "view agencies" do
          login_as @admin
          visit root_path
          click_link 'Agencies'
          expect(page).to have_content "Title"
          expect(page).to have_content "Description"
        end 
      end
  end

end