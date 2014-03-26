class AddCoordsToUser < ActiveRecord::Migration
  def change
    add_column :users, :address, :text
    add_column :users, :lat, :decimal, :precision => 9, :scale => 6
    add_column :users, :lng, :decimal, :precision => 9, :scale => 6
    add_index :users, [:lat, :lng]
  end
end