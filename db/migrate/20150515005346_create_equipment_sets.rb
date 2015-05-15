class CreateEquipmentSets < ActiveRecord::Migration
  def change
    create_table :equipment_sets do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
