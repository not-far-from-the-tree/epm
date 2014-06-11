class ChangeSnailMailDefaultToFalse < ActiveRecord::Migration
  def change
    change_column_default :users, :snail_mail, false
  end
end