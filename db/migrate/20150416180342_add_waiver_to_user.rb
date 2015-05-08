class AddWaiverToUser < ActiveRecord::Migration
  def change
  	add_column :users, :waiver, :boolean, :default => false
  	User.all.update_all(:waiver => true)
  end
end
