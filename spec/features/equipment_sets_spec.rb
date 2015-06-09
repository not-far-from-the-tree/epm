require 'spec_helper'

describe "Equipment Sets" do

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
        it "create an equipment set with title and description" do
          login_as @admin
          visit root_path
          click_link 'Equipment Sets'
          click_link 'New Equipment Set'
          es = build :full_equipment_set
          fill_in 'Title', with: es.title
          fill_in 'Description', with: es.description
          click_button 'Create Equipment set'
          expect(current_path).to eq equipment_set_path(EquipmentSet.last.id)
          expect(page).to have_content es.title
          expect(page).to have_content es.description
        end 

        it "create an equipment set with title but no description" do
          login_as @admin
          visit root_path
          click_link 'Equipment Sets'
          click_link 'New Equipment Set'
          es = build :full_equipment_set
          fill_in 'Title', with: es.title
          click_button 'Create Equipment set'
          expect(current_path).to eq equipment_set_path(EquipmentSet.last.id)
          expect(page).to have_content es.title
        end 

        it "try to create an equipment set with no title and no description" do
          login_as @admin
          visit root_path
          click_link 'Equipment Sets'
          click_link 'New Equipment Set'
          es = build :full_equipment_set
          fill_in 'Title', with: ""
          fill_in 'Description', with: ""
          click_button 'Create Equipment set'
          expect(current_path).to eq equipment_sets_path
          expect(page).to have_content "Title can't be blank"
        end 
      end
  end



  context "using" do
      context "as admin" do
        it "selects an equipment set for an event with no date yet" do
          login_as @admin
          visit root_path
          click_link 'Add New Event'
          expect(page).not_to have_content "Equipment set"
        end 

        it "selects an equipment set for an event with with date", js: true do
          login_as @admin
          visit root_path
          click_link 'Equipment Sets'
          click_link 'New Equipment Set'
          es = build :full_equipment_set
          fill_in 'Title', with: es.title
          fill_in 'Description', with: es.description
          click_button 'Create Equipment set'
          visit new_event_path
          find('.ui-datepicker-trigger').click;
          within '.ui-datepicker' do
            click_link 28 # select date towards the end of the current month
          end
          expect(page).to have_select 'event[equipment_set_id]'
          select es.title, :from => "event[equipment_set_id]"
          click_button 'Save'
          expect(page).to have_content es.title
        end 
      end
  end


  context "viewing" do
      context "as participant" do
        it "can't view equipment sets" do
          login_as @participant
          visit root_path
          expect(page).not_to have_content "Equipment Sets"
        end
      end 

      context "as admin" do
        it "view equipment sets" do
          login_as @admin
          visit root_path
          click_link 'Equipment Sets'
          expect(page).to have_content "Title"
          expect(page).to have_content "Description"
        end 
      end
  end


end