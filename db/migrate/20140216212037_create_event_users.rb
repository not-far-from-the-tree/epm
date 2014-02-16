class CreateEventUsers < ActiveRecord::Migration
  def change
    create_table :event_users do |t|
      t.references :event, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end