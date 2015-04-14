class UserTreeDetails < ActiveRecord::Migration
  def change
  	 add_column :trees, :relationship, :string
     add_column :users, :ladder, :string
     add_column :users, :contactnotes, :text
     add_column :users, :propertynotes, :text
  end
end