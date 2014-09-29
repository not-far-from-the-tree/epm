class AddNumEventsParticipatedToUser < ActiveRecord::Migration
  def change
    add_column :users, :num_participated_events, :integer, default: 0
    remove_column :users, :virgin
  end
end
