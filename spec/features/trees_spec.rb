require 'spec_helper'

describe "Trees" do

  include Warden::Test::Helpers
  before :each do
    @admin = create :admin
    @participant = create :participant
  end
  after :each do
    Warden.test_reset!
  end

    context "creating" do
        it "create a tree with species and owner" do
          login_as @participant
          @tree = build :tree
          visit root_path
          click_link 'My Trees'
          click_link 'Add a Tree'
          choose @tree.species
          choose 'Property Owner'
          click_button 'Create Tree'
          expect(current_path).to eq tree_path(Tree.last.id)
          expect(page).to have_content @tree.species
          expect(page).to have_content @participant.address
        end 

        it "create a full tree with species and owner" do
          @tree = build :full_tree
          @owner = create :full_tree_owner
          login_as @owner
          visit root_path
          click_link 'My Trees'
          click_link 'Add a Tree'
          choose @tree.species
          fill_in "Subspecies", with: @tree.subspecies
          fill_in "Treatment", with: @tree.treatment
          choose "tree_keep_"+@tree.keep.to_s
          fill_in "tree_additional", with: @tree.additional
          select Tree.height_labels.key(@tree.height.to_sym), from: "Height"
          choose 'Property Owner'
          click_button 'Create Tree'
          expect(current_path).to eq tree_path(Tree.last.id)
          expect(page).to have_content @tree.species
          expect(page).to have_content @tree.subspecies
          expect(page).to have_content @tree.treatment
          expect(page).to have_content Tree.keep_result_labels.key(@tree.keep.to_sym)
          expect(page).to have_content @tree.additional
          expect(page).to have_content Tree.height_labels.key(@tree.height.to_sym)
          # owner information
          expect(page).to have_content @owner.address
          # expect(page).to have_content User.ladder_show_labels.key(@owner.ladder.to_sym)
          expect(page).to have_content @owner.propertynotes
        end 


        it "create a tree with species by Tenant", js: true do
          @owner = build :participant
          @tree = build :full_tree
          login_as @participant
          visit root_path
          click_link 'My Trees'
          click_link 'Add a Tree'
          choose @tree.species
          choose 'Tenant'
          fill_in 'E-mail Address', with: @owner.email
          fill_in 'Fruit Tree Address', with: @owner.address
          fill_in 'tree_owner_attributes_fname', with: @owner.fname
          fill_in 'tree_owner_attributes_lname', with: @owner.lname
          click_button 'Create Tree'
          expect(current_path).to eq tree_path(Tree.last.id)
          expect(page).to have_content @tree.species
          expect(page).to have_content @participant.fname
          expect(page).to have_content @participant.lname
          expect(page).to have_content @participant.email
          expect(page).to have_content @owner.address
        end 

        it "create a tree with species by Friend", js: true do
          @owner = build :participant
          @tree = build :full_tree
          login_as @participant
          visit root_path
          click_link 'My Trees'
          click_link 'Add a Tree'
          choose @tree.species
          choose 'Friend'
          fill_in 'E-mail Address', with: @owner.email
          fill_in 'Fruit Tree Address', with: @owner.address
          fill_in 'tree_owner_attributes_fname', with: @owner.fname
          fill_in 'tree_owner_attributes_lname', with: @owner.lname
          click_button 'Create Tree'
          expect(current_path).to eq tree_path(Tree.last.id)
          expect(page).to have_content @tree.species
          expect(page).to have_content @participant.fname
          expect(page).to have_content @participant.lname
          expect(page).to have_content @participant.email
          expect(page).to have_content @owner.address
        end 

        it "does not allow user create a tree without permission", js: true do
          @owner = build :participant
          @tree = build :full_tree
          login_as @participant
          visit root_path
          click_link 'My Trees'
          click_link 'Add a Tree'
          choose @tree.species
          choose "I don't have permission to add this tree"
          expect(page).to have_content "If you don't already have permission"
          expect(page).not_to have_button 'Create Tree'
          expect(current_path).to eq new_tree_path
        end 

        it "Allows user create a tree from no permission to permission", js: true do
          @owner = build :participant
          @tree = build :full_tree
          login_as @participant
          visit root_path
          click_link 'My Trees'
          click_link 'Add a Tree'
          choose @tree.species
          choose "I don't have permission to add this tree"
          expect(page).to have_content "If you don't already have permission"
          expect(page).not_to have_button 'Create Tree'
          choose 'Friend'
          fill_in 'E-mail Address', with: ((User.last.id + 1).to_s + "@example.com")
          fill_in 'Fruit Tree Address', with: @owner.address
          fill_in 'tree_owner_attributes_fname', with: @owner.fname
          fill_in 'tree_owner_attributes_lname', with: @owner.lname
          click_button 'Create Tree'
          expect(current_path).to eq tree_path(Tree.last.id)
          expect(page).to have_content @tree.species
          expect(page).to have_content @participant.fname
          expect(page).to have_content @participant.lname
          expect(page).to have_content @participant.email
          expect(page).to have_content @owner.address
        end 

        # doesnt allow people to add a tree as not pickable
        # add this when pickable and not_pickable_reason is added to form

        it "Doesn't allow non-admin non-submitter/owner to view" do
          @tree = create :short_tree, :owner
          login_as @participant
          visit tree_path(@tree.id)
          expect(page).to have_content "Sorry"
        end

        it "Allows owner to add a similar tree" do
          @tree = create :propertyowner_tree, :owner
          login_as @tree.owner
          visit tree_path(@tree)
          click_link "Add a new tree exactly like this"
          #expect(find_field(@tree.species)).to be_checked
          expect(find('#tree_subspecies').value).to have_content @tree.subspecies
          expect(find('#tree_treatment').value).to have_content @tree.treatment
          within_fieldset('Do you want to keep 1/3 of the fruit') do 
            choose Tree.keep_labels.key(@tree.keep.to_sym)
          end
          expect(find('#tree_additional').value).to have_content @tree.additional
          within_fieldset('Height') do 
            expect(find_field('tree_height').find('option[selected]').text).to have_content Tree.height_labels.key(@tree.height.to_sym)
          end
          click_button "Update Tree"
          expect(page).to have_content @tree.species
          expect(page).to have_content @tree.subspecies
          expect(page).to have_content @tree.treatment
          expect(page).to have_content Tree.keep_result_labels.key(@tree.keep.to_sym)
          expect(page).to have_content @tree.additional
          expect(page).to have_content Tree.height_labels.key(@tree.height.to_sym) 
          expect(page).to have_content @tree.owner.address          
        end

        it "Allows owner to add a similar tree with changes" do
          @tree = create :propertyowner_tree, :owner
          @difference = build :full_tree
          login_as @tree.owner
          visit tree_path(@tree)
          click_link "Add a new tree exactly like this"
          #expect(find_field(@tree.species)).to be_checked
          expect(find('#tree_subspecies').value).to have_content @tree.subspecies
          expect(find('#tree_treatment').value).to have_content @tree.treatment
          expect(find('#tree_treatment').value).to have_content @tree.treatment #keep
          expect(find('#tree_additional').value).to have_content @tree.additional
          expect(find('#tree_height option[selected]').text).to have_content Tree.height_labels.key(@tree.height.to_sym)
          fill_in 'Treatment', with: @difference.treatment
          choose @difference.species
          click_button "Update Tree"
          expect(page).to have_content @difference.species
          expect(page).to have_content @tree.subspecies
          expect(page).to have_content @difference.treatment
          expect(page).to have_content Tree.keep_result_labels.key(@tree.keep.to_sym)
          expect(page).to have_content @tree.additional
          expect(page).to have_content Tree.height_labels.key(@tree.height.to_sym) 
          expect(page).to have_content @tree.owner.address         
        end

        it "Allows owner to add a tree at same location" do
          @tree = create :propertyowner_tree, :owner
          @difference = build :full_tree
          login_as @tree.owner
          visit tree_path(@tree)
          click_link "Add a new tree with this location"
          fill_in 'Treatment', with: @difference.treatment
          fill_in 'Subspecies', with: @difference.subspecies
          choose @difference.species
          click_button "Update Tree"
          expect(page).to have_content @difference.species
          expect(page).to have_content @difference.subspecies
          expect(page).to have_content @difference.treatment
          expect(page).to have_content @tree.owner.address         
        end     

    end

    context "viewing" do
        it "as admin can see trees in owner profiles" do
          @tree = create :full_tree, :owner
          login_as @admin
          visit user_path(@tree.owner)
          expect(page).to have_content @tree.species
          expect(page).to have_content @tree.owner.address
        end

        it "as owner can see trees in 'My Trees'" do
          @tree = create :full_tree, :owner
          login_as @tree.owner
          visit root_path
          click_link "My Trees"
          expect(page).to have_content @tree.species
        end
      # does let admin and owner set pickable to false and not_pickable_reason
    end
end