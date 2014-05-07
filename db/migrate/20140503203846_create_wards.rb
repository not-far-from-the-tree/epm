class CreateWards < ActiveRecord::Migration

  def change

    create_table :wards do |t|
      t.string :name
      t.timestamps
    end

    create_table :user_wards do |t|
      t.references :user, index: true
      t.references :ward, index: true
      t.timestamps
    end

    add_reference :events, :ward, index: true

  end

end