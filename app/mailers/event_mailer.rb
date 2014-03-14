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

  def cancel(event, users)
    @event = event
    mail bcc: users.map{|u| to(u)}, subject: "#{@event.display_name} has been cancelled"
  end

  def change(event, users)
    @event = event
    # @user is for checking permissions -
    #   can pass in the first user 'cause we're passing in users who all have the same permissions
    @user = users.first
    mail bcc: users.map{|u| to(u)}, subject: 'Changes to an event you are attending'
  end

  private

    def to(user)
      user.name.present? ? "#{user.name} <#{user.email}>" : user.email
    end

end
