class RemoveLatAndLngFromTree < ActiveRecord::Migration
  def change
  	remove_column :trees, :lat
  	remove_column :trees, :lng
  end
end
