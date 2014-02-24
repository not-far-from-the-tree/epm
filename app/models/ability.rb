class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new
    if user.persisted?
      can :read, Event
      can [:read, :update], User, :id => user.id
      if user.has_role? :admin
        can [:create, :update, :destroy], Event
        can :read, User
      end
      if user.has_role? :participant
        can [:attend, :unattend], Event
      end
    end

  end
end