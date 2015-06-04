class AddNotPickableReasonToTree < ActiveRecord::Migration
  def change
    add_column :trees, :not_pickable_reason, :string
  end
end
