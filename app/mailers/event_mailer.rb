class EventMailer < ActionMailer::Base

  default from: "#{Configurable.title} <#{Configurable.email}>"

  def attend(event, user)
    @event = event
    @user = user
    mail to: to(user), subject: 'You have joined an event'
  end

  def coordinator_assigned(event)
    @event = event
    mail to: to(@event.coordinator), subject: 'You have been assigned an event'
  end

  private

    def to(user)
      user.name.present? ? "#{user.name} <#{user.email}>" : user.email
    end

end
