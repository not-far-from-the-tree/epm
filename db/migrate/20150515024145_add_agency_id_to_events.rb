class AddAgencyIdToEvents < ActiveRecord::Migration
  def change
  	add_column :events, :agency_id, :integer
  end
end
