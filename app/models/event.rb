class Event < ActiveRecord::Base

  strip_attributes

  validates :start, :finish, presence: true

  validate :must_start_before_finish
  def must_start_before_finish
    if start.present? && finish.present? && start > finish
      errors.add(:finish, "must be after the start")
    end
  end

  has_many :event_users, dependent: :destroy
  has_many :participants, through: :event_users, source: :user

  default_scope { order :start }
  scope :past, -> { where('finish < ?', Time.zone.now).order('finish DESC') }
  scope :not_past, -> { where 'finish > ?', Time.zone.now }
  scope :not_attended_by, ->(user) { joins('LEFT JOIN event_users ON events.id = event_users.event_id').where("events.id NOT IN (SELECT event_id FROM event_users WHERE user_id = #{user.id})").group('events.id') }

  def past?
    @is_past ||= finish < Time.zone.now
  end

  include ActionView::Helpers::TextHelper
  def display_name
    return name if name.present?
    return truncate(description, length: 50, separator: ' ') if description.present?
    return self.when if start.present? && finish.present?
    return '(untitled event)'
  end

  def when
    "#{start.strftime '%B %d %Y, %l:%M %p'} to #{finish.strftime '%B %d %Y, %l:%M %p'}"
  end

end