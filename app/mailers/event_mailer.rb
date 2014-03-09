class EventMailer < ActionMailer::Base

  default from: "from@example.com" # todo: eventually replace with config

  def attend(event, user)
    @event = event
    @user = user
    to = @user.name.present? ? "#{@user.name} <#{@user.email}>" : @user.email
    mail to: to, subject: 'You have joined an event'
  end

end
