class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new

    if user.persisted?

      can :read, Event, can_have_participants?: true
      can :past, Event
      can [:show, :update], User, id: user.id

      if user.has_role? :admin
        can :manage, Event
        can [:read, :add_role], User
      end

      if user.has_role? :coordinator
        can :read, Event
        can [:update, :destroy], Event, coordinator_id: user.id
        can :update, Event, coordinator_id: nil
      end

      if user.has_role? :participant
        can [:attend, :unattend], Event
      end

    end

  end

end