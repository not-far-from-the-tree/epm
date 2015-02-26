class AddLatAndLngToTree < ActiveRecord::Migration
  def change
    add_column :trees, :lat, :decimal, precision: 9, scale: 6
    add_column :trees, :lng, :decimal, precision: 9, scale: 6
  end          
end
