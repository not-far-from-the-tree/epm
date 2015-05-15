class AddEquipmentSetIdToEquipmentSet < ActiveRecord::Migration
  def change
  	add_column :events, :equipment_set_id, :integer
  end
end
