class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new

    if user.persisted?

      can :read, Event, can_have_participants?: true
      can :calendar, Event
      can :index, :geocode

      can [:show, :update], User, id: user.id
      can :destroy, Role, user_id: user.id
      can :deactivate, User do |user|
        user.roles.reject{|r| user.ability.can?(:destroy, r)}.empty?
      end

      if user.has_role? :admin
        can :manage, [Event, Role, :setting]
        can :read, User
      end

      if user.has_role? :coordinator
        can :read, Event
        can [:update, :ask_to_cancel, :cancel, :read_notes], Event, coordinator_id: user.id
        can :update, Event, coordinator_id: nil
      end

      if user.has_role? :participant
        can [:attend, :unattend], Event
      end

    end

  end

end