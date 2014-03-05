class Event < ActiveRecord::Base

  strip_attributes

  validate :must_start_before_finish
  validate :must_not_be_empty
  validates :finish, presence: true, if: "start.present?"
  def must_start_before_finish
    if start.present? && finish.present? && start > finish
      errors.add(:finish, 'must be after the start')
    end
  end
  def must_not_be_empty
    if start.blank? && name.blank? && description.blank?
      errors.add(:base, 'An event must have a name, description, or date')
    end
  end
  before_validation do |event|
    event.finish = nil if event.start.blank?
  end

  has_many :event_users, dependent: :destroy
  has_many :participants, through: :event_users, source: :user
  belongs_to :coordinator, class_name: 'User'

  default_scope { order :start }
  scope :past, -> { where('finish < ?', Time.zone.now).reorder('finish DESC') }
  scope :not_past, -> { where 'start IS NULL OR finish > ?', Time.zone.now }
  # for not_attended_by, not sure why coordinator_id needs a separate null check. is this just a sqlite thing?
  scope :not_attended_by, ->(user) { joins('LEFT JOIN event_users ON events.id = event_users.event_id').where("events.id NOT IN (SELECT event_id FROM event_users WHERE user_id = ?) AND (coordinator_id IS NULL OR coordinator_id != ?)", user.id, user.id).distinct }
  scope :coordinatorless, -> { where coordinator: nil }
  scope :dateless, -> { where start: nil }
  scope :participatable, -> { where 'start IS NOT NULL AND coordinator_id IS NOT NULL' }

  attr_reader :start_day, :start_time
  def assign_attributes(attrs)
    # if inputing start in parts (day and time), then combine them
    start_day = attrs.delete(:start_day)
    start_time = attrs.delete(:start_time)
    attrs[:start] = "#{start_day} #{start_time}" if attrs[:start].blank? && start_day.present? && start_time.present?
    # this is needed because during mass assignment, we can't guarantee that :start will be set before :duration
    dur = attrs.delete(:duration)
    super(attrs)
    self.duration = dur
  end
  def duration=(timespan)
    if start.present? && timespan.present? && timespan.to_i > 0
      self.finish = start + timespan.to_i
    else
      nil
    end
  end
  def duration
    (start.present? && finish.present?) ? (finish - start).round : nil
  end
  def duration_hours
    duration.present? ? (duration / 3600) : nil
  end

  def past?
    finish.present? ? finish < Time.zone.now : nil
  end

  include ActionView::Helpers::TextHelper # needed for truncate()
  def display_name
    return name if name.present?
    return truncate(description, length: 50, separator: ' ') if description.present?
    return start.strftime('%B %e %Y, %l:%M %p').gsub('  ', ' ') if start.present?
    '(untitled event)'
  end

  def participatable_by?(user)
    can_have_participants? && !past? && (user != coordinator) && user.has_role?(:participant)
  end

  def can_have_participants?
    start.present? && coordinator.present?
  end

end