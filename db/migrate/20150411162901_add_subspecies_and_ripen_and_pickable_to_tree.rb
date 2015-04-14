class AddSubspeciesAndRipenAndPickableToTree < ActiveRecord::Migration
  def change
    add_column :trees, :subspecies, :string
    add_column :trees, :ripen, :date
    add_column :trees, :pickable, :boolean
  end
end
