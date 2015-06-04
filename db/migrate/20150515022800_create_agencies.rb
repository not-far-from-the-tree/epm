class CreateAgencies < ActiveRecord::Migration
  def change
    create_table :agencies do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end