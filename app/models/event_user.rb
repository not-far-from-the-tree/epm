class EventUser < ActiveRecord::Base

  belongs_to :event
  belongs_to :user
  validates :user_id, :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event }

  validate :event_must_accept_participant
  def event_must_accept_participant
    if event.present? && user.present? && !event.participatable_by?(user)
      errors.add(:event, 'must accept participants')
    end
  end

  # note: most of these status values are not yet implemented
  enum status: [
    :invited, # admin/coordinator has invited the participant
    :requested, # the participant has requested to attend, for events which require admin/coordinator approval
    :attending, # participant will attend (or if the event has passed, was planning to attend and may have)
    :not_attending, # admin/coordinator has invited the participant, who said 'no'
    :waitlisted, # participant would like to attend (or to have attended) but event is full
    :denied, # admin/coordinator has denied the participant the ability to participate
    :withdrawn, # participant had requested or been waitlisted, but then withdrew their request
    :cancelled, # participant had been 'attending' but changed their rsvp to 'no'
    :attended, # participant had intended to attend, and did so
    :no_show # participant had intended to attend, but never showed up
  ]
  validates :status, presence: true


  # for now these methods only handle actions by the user in question (i.e. not an admin or the event's coordinator)
  # these methods are currently tested (only) through their equivalent methods in the event model;
  #   will need to test separately when they are accessed separately (todo)

  def attend
    return false if event.past?
    # todo: does not handle :requested status
    if [nil, 'invited', 'not_attending', 'withdrawn', 'cancelled'].include? status
      self.status = event.full? ? :waitlisted : :attending
      save
    end
    self
  end

  def unattend
    return false if event.past?
    was_attending = attending?
    if invited?
      self.status = :not_attending
    elsif attending?
      self.status = :cancelled
    elsif waitlisted? || requested?
      self.status = :withdrawn
    end
    if self.status # i.e. don't need to save if trying to unattend when there was no record of attendance anyway
      if save && was_attending && cancelled? && ( event.time_until > 5.hours ) # todo: allow configurability of this number
        event.add_from_waitlist
      end
    end
    self
  end

end