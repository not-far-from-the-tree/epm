class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new

    if user.persisted?

      can :read, Event, can_have_participants?: true
      can :calendar, Event
      can :index, :geocode

      can :me, User
      can [:show, :read_contact, :read_attendance, :read_address, :update], User, id: user.id
      can :destroy, Role, user_id: user.id
      can :deactivate, User do |u|
        u.roles.reject{|r| can? :destroy, r }.empty?
      end

      if user.has_role? :admin
        can :manage, [Event, Role, :setting]
        cannot :claim, Event
        can [:index, :map, :show, :read_contact, :read_attendance], User
      end

      if user.has_role? :coordinator
        can :read, Event
        can [:claim, :read_notes], Event, coordinator_id: nil
        can [:update, :read_notes, :read_specific_location, :who, :invite, :take_attendance], Event, coordinator_id: user.id
        can [:show, :read_attendance], User
      end

      if user.has_role? :participant
        can [:attend, :unattend], Event
        can :read_specific_location, Event do |event|
          !event.hide_specific_location || event.participants.include?(user)
        end
      end

    end

  end

end