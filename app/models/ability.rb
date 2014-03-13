class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new

    if user.persisted?

      can :read, Event, can_have_participants?: true
      can :calendar, Event
      can [:show, :update], User, id: user.id
      can :destroy, Role, user_id: user.id

      if user.has_role? :admin
        can :manage, [Event, Role, :setting]
        can :read, User
      end

      if user.has_role? :coordinator
        can :read, Event
        can [:update, :destroy, :read_notes], Event, coordinator_id: user.id
        can :update, Event, coordinator_id: nil
      end

      if user.has_role? :participant
        can [:attend, :unattend], Event
      end

    end

  end

end