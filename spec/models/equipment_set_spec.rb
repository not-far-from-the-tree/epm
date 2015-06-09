require 'spec_helper'

describe EquipmentSet do

  context "validity" do

    it "is invalid without a title" do
      expect(build :short_equipment_set, title: nil).not_to be_valid
    end

    it "is valid without a description" do
      expect(build :short_equipment_set, description: nil).to be_valid
    end

    it "is valid with a name and description" do
      expect(build :full_equipment_set).to be_valid
    end

  end

  context "attributes" do

      it "has a title" do
        expect(build(:short_equipment_set).title).not_to be_blank
      end

      it "has a description" do
        expect(build(:full_equipment_set).description).not_to be_blank
      end

  end
end
