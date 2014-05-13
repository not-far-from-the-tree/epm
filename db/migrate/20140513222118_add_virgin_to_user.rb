class AddVirginToUser < ActiveRecord::Migration
  def change
    add_column :users, :virgin, :boolean, default: true
  end
end