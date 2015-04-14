class AddSubmitterIdAndRenameUserIdtoOwnerIdInTree < ActiveRecord::Migration
  def change
  	add_column :trees, :submitter_id, :integer
  	rename_column :trees, :user_id, :owner_id
  end
end
