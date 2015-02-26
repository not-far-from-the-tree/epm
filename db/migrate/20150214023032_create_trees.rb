class CreateTrees < ActiveRecord::Migration
  def change
    create_table :trees do |t|
      t.string :species
      t.string :address

      t.timestamps
    end
  end
end
