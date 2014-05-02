class ReworkUserNames < ActiveRecord::Migration
  def change
    remove_column :users, :name
    remove_column :users, :handle
    remove_column :users, :description
    add_column :users, :fname, :string
    add_column :users, :lname, :string
  end
end
