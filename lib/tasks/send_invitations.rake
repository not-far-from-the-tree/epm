task :send_invitations => :environment do

  # get all the events that have potential invitations
  # remove ones that have been filled, cancelled, or whichever
  events = Event.where id: Invitation.pluck(:event_id).uniq
  events = events.to_a.partition{|e| e.can_accept_participants? && !e.full?}
  Invitation.where(event_id: events.last.map{|e| e.id}).destroy_all if events.last.any?

  events.first.each do |event|

    invites_sent = 0
    Invitation.where(event_id: event.id).each do |invite|
      eu = event.event_users.create user_id: invite.user_id, status: :invited
      if eu.valid? # this prevents inviting people already involved, who are no longer participants, etc.
        invites_sent += 1
        EventMailer.invite(event, invite.user).deliver
      end
      invite.destroy
      break if invites_sent >= 5
    end

  end

end