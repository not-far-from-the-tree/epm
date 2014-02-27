class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new
    if user.persisted?
      can :read, Event
      can [:read, :update], User, :id => user.id
      if user.has_role? :admin
        can [:create, :update, :destroy], Event
        can [:read, :add_role], User
      end
      if user.has_role? :coordinator
        can [:update, :destroy], Event, :coordinator_id => user.id
        can :update, Event, :coordinator_id => nil
      end
      if user.has_role? :participant
        can [:attend, :unattend], Event
      end
    end

  end
end