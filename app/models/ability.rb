class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new

    can :index, :geocode
    
    if user.persisted?
      can :manage, Tree
      can :read, Event, can_have_participants?: true
      can [:dashboard, :calendar], Event
      

      can [:me, :my_wards], User
      can [:show, :read_contact, :read_attendance, :update], User, id: user.id
      can :destroy, Role, user_id: user.id
      can :deactivate, User do |u|
        u.roles.reject{|r| can? :destroy, r }.empty?
      end

      if user.has_role? :admin
        can :manage, [Event, Role, EquipmentSet, Agency, :setting]
        cannot [:claim, :attend], Event
        can [:index, :map, :show, :read_contact, :read_attendance, :update, :destroy, :invite], User
      end

      if user.has_role? :coordinator
        can :manage, [EquipmentSet]
        can :read, Agency
        can [:read, :create], Event
        can [:claim, :read_notes], Event, coordinator_id: nil
        can [:unclaim, :update, :read_notes, :read_specific_location, :who, :invite, :take_attendance], Event, coordinator_id: user.id
        # actually coordinators can only edit *some* event fields
        #   however that authorization is handled *not* through cancan
        #   but rather through an event's can_edit_attribute? method
        can [:show, :read_attendance], User
      end

      if user.has_role? :participant
        can [:attend, :unattend], Event
        cannot :index, Tree
        can :read_specific_location, Event do |event|
          !event.hide_specific_location || event.participants.include?(user)
        end
      end

    end

  end

end