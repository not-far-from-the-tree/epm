class AddMinAndMaxToEvent < ActiveRecord::Migration
  def change
    add_column :events, :min, :integer, default: 0
    add_column :events, :max, :integer
  end
end