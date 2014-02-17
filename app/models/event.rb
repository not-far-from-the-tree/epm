class Event < ActiveRecord::Base

  validates :start, :finish, presence: true

  has_many :event_users
  has_many :participants, through: :event_users, source: :user

end
