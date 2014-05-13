class AddSendByToInvitation < ActiveRecord::Migration
  def change
    add_column :invitations, :send_by, :datetime
  end
end