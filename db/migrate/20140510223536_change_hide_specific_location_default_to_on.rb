class ChangeHideSpecificLocationDefaultToOn < ActiveRecord::Migration
  def change
    change_column_default :events, :hide_specific_location, true
  end
end