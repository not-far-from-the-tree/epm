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

  # note: not all the status values are used (yet)
  enum status: [:invited, :requested, :attending, :not_attending, :waitlisted, :denied, :withdrawn, :cancelled, :attended, :no_show]
  validates :status, presence: true

end