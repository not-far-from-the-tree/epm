class CreateEventTrees < ActiveRecord::Migration
  def change
    create_table :event_trees do |t|
      t.references :event, index: true
      t.references :tree, index: true

      t.timestamps
    end
  end
end
