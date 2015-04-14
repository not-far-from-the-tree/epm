class ExpandedTrees < ActiveRecord::Migration
  def change
    add_reference :trees, :users, index: true
    add_column :trees, :height, :integer, default: 0
    add_column :trees, :treatment, :text
    add_column :trees, :keep, :integer
    add_column :trees, :additional, :text
    remove_column :trees, :address
  end
end