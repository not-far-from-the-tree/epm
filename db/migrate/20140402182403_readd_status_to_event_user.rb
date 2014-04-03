class ReaddStatusToEventUser < ActiveRecord::Migration
  def change
    remove_column :event_users, :status, :integer # removes column that has a default specified
    add_column :event_users, :status, :integer # readds column, no default specified
  end
end