class AddNameAndDescriptionToEvent < ActiveRecord::Migration
  def change
    add_column :events, :name, :string
    add_column :events, :description, :text
  end
end
