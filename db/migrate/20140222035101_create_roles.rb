class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.references :user, index: true
      t.integer :name

      t.timestamps
    end
  end
end
