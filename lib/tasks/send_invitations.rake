task :send_invitations => :environment do

  # todo: don't invite people to full events (?)

  Invitation.where("send_by < ?", Time.zone.now).find_each do |invitation|
    EventMailer.invite(invitation.event, invitation.user).deliver
    invitation.destroy
  end

end