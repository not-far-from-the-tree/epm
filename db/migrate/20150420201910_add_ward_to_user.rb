class AddWardToUser < ActiveRecord::Migration
  def change
    add_column :users, :home_ward, :integer
  end
end
