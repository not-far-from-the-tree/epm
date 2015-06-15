class ChangeLadderToInteger < ActiveRecord::Migration
  def change
  	remove_column :users, :ladder
    add_column :users, :ladder, :integer
  end
end
