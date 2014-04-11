class AddHideSpecificLocationToEvent < ActiveRecord::Migration
  def change
    add_column :events, :hide_specific_location, :boolean, default: false
  end
end
