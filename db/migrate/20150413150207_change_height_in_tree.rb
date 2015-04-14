class ChangeHeightInTree < ActiveRecord::Migration
  def change
  	change_column :trees, :height, :string
  end
end
