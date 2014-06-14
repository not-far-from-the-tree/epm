class EventMailer < ActionMailer::Base

  default from: "#{Configurable.title} <#{Configurable.email}>"

  include ActionView::Helpers::TextHelper # needed for pluralize()

  # in many of these methods, @user is for checking permissions -
  #   usually passing in an array of users who all have the same permissions so can just use the first

  def attend(event, users)
    users = [*users]
    @event = event
    # users are all participants, but as some could also be admins, need to do this for permissions:
    @user = users.find{|u| u.ability.cannot?(:read_notes, event)} || users.first
    mail bcc: to(users), subject: "Attending: event.display_name(@user)"
  end

  def unattend(event, users, reason = nil)
    @event = event
    @reason = reason
    mail bcc: to(users), subject: "You are no longer attending #{event.display_name}"
  end

  def coordinator_needed(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "#{@event.display_name(@user)} needs #{Configurable.coordinator.capitalize.indefinitize}"
  end

  def coordinator_assigned(event)
    @event = event
    mail to: to(@event.coordinator), subject: "You have been assigned to lead #{@event.display_name(@event.coordinator)}"
  end

  def cancel(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "#{@event.display_name(@user)} has been cancelled"
  end

  def change(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "Changes to #{@event.display_name(@user)}"
  end

  def awaiting_approval(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "#{@event.display_name(@user)} is awaiting approval"
  end

  def approve(event)
    @event = event
    mail to: to(event.coordinator), subject: "Approved: #{@event.display_name(event.coordinator)}"
  end

  def invite(event, users)
    @event = event
    users = [*users]
    # users are all participants, but as some could also be admins, need to do this for permissions:
    @user = users.find{|u| u.ability.cannot?(:read_notes, event)} || users.first
    mail bcc: to(users), subject: "Invite: #{event.display_name(@user)}"
  end

  def remind(event, users = nil)
    @event = event
    users ||= @event.users
    @user = users.find{|u| u.ability.cannot?(:read_notes, event)} || users.first
    mail bcc: to(users), subject: "Reminder: #{event.display_name} is in #{pluralize event.hours_until, 'hour'}"
  end

  private

    def to(users)
      return users.map{|u| to(u)} unless users.is_a? User
      n = "#{users.fname} #{users.lname}".strip
      n.present? ? "#{n} <#{users.email}>" : users.email
    end

end
