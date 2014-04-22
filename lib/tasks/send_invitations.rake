task :send_invitations => :environment do

  Invitation.find_each do |invitation|
    EventMailer.invite(invitation.event, invitation.user).deliver
    invitation.destroy
  end

end