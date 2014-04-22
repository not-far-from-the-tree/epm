every 1.day, at: '12:00 am' do
  rake 'send_next_day_reminders'
end

every 30.minutes do
  rake 'send_invitations'
end