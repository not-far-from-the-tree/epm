class FixUserId < ActiveRecord::Migration
  def change
  	rename_column :trees, :users_id, :user_id
  end
end
