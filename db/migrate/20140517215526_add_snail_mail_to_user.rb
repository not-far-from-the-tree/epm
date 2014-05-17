class AddSnailMailToUser < ActiveRecord::Migration
  def change
    add_column :users, :snail_mail, :boolean, default: true
  end
end