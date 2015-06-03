class AddDoNotContactReasonToUsers < ActiveRecord::Migration
  def change
    add_column :users, :do_not_contact_reason, :string
    add_column :users, :can_email, :boolean
    add_column :users, :can_mail, :boolean
    add_column :users, :can_phone, :boolean
  end
end
