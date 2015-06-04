class ChangeHeightTypeToEnumInTree < ActiveRecord::Migration
  def change
  	remove_column :trees, :height
    add_column :trees, :height, :integer
  end
end
