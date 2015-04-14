class AddWardToUsers < ActiveRecord::Migration
  def change
    add_column :users, :ward, :integer
  end
end
