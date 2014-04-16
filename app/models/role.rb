class Role < ActiveRecord::Base

  validates :name, presence: true

  belongs_to :user

  enum name: [:admin, :coordinator, :participant]
  validates :name, uniqueness: { scope: :user_id }

  default_scope { order :name }

  before_destroy do |role|
    response = true
    if role.name == 'admin' && User.admins.count == 1
      errors.add :base, 'Admin role cannot be removed if there are no other admins'
      response = false
    end
    response
  end

  attr_accessor :destroyed_by_self # boolean, set just before calling .destroy()
  after_destroy do |role|
    if role.name == 'coordinator'
      events = role.user.coordinating_events.not_past.not_cancelled
      if events.any?
        events.update_all(coordinator_id: nil)
      end
    elsif role.name == 'participant'
      Event.not_past.not_cancelled
        .includes(:event_users).where(
          'event_users.user_id' => role.user.id,
          'event_users.status' => EventUser.statuses_array(:requested, :invited, :attending, :waitlisted)
        )
        .each{|e| e.event_users.first.unattend destroyed_by_self }
    end
  end

end