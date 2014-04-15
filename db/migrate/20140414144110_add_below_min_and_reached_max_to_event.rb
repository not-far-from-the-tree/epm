class AddBelowMinAndReachedMaxToEvent < ActiveRecord::Migration
  def change
    add_column :events, :below_min, :boolean, default: false
    add_column :events, :reached_max, :boolean, default: false
  end
end
