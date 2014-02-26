class AddCoordinatorIdToEvent < ActiveRecord::Migration
  def change
    add_column :events, :coordinator_id, :integer
    add_index :events, :coordinator_id
  end
end
