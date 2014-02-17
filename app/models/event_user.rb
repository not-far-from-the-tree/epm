class EventUser < ActiveRecord::Base

  belongs_to :event
  belongs_to :user

  validates :user_id, :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event }

end