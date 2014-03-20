class AddCoordsToEvent < ActiveRecord::Migration
  def change
    add_column :events, :address, :text
    add_column :events, :lat, :decimal, :precision => 9, :scale => 6
    add_column :events, :lng, :decimal, :precision => 9, :scale => 6
    add_index :events, [:lat, :lng]
   end
end