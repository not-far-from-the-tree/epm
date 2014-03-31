class AddStatusToEventUser < ActiveRecord::Migration

  def change
    add_column :event_users, :status, :integer, default: 2
  end

end