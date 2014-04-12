task :send_next_day_reminders => :environment do

  Event.will_happen_in_two_days.each do |event|
    # todo: send separate emails to coordinator (and possibly admin)
    EventMailer.remind(event).deliver if event.users.any?
  end

end