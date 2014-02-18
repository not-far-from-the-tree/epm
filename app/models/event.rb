class Event < ActiveRecord::Base

  validates :start, :finish, presence: true

  has_many :event_users
  has_many :participants, through: :event_users, source: :user

  default_scope { order :start }
  scope :past, -> { where('finish < ?', Time.zone.now).order('finish DESC') }
  scope :not_past, -> { where 'finish > ?', Time.zone.now }
  scope :not_attended_by, ->(user) { joins('LEFT JOIN event_users ON events.id = event_users.event_id').where("events.id NOT IN (SELECT event_id FROM event_users WHERE user_id = #{user.id})").group('events.id') }

end