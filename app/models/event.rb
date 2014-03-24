class Event < ActiveRecord::Base

  strip_attributes
  def self.significant_attributes
    # i.e. if any of these attributes change, attendees should be notified and may need to cancel
    [:start, :finish, :name, :description, :address, :lat, :lng]
  end
  def changed_significantly?
    self.class.significant_attributes.each do |attr|
      self.send("#{attr}=", nil) if self.send(attr).blank? # this is needed because strip_attributes nullifies, but only before validation
      return true if self.send("#{attr}_changed?")
    end
    false
  end

  enum status: [:proposed, :approved, :cancelled]

  validate :must_not_be_empty
  def must_not_be_empty
    if start.blank? && name.blank? && description.blank? && address.blank? && !coords
      errors.add(:base, 'An event must have a name, description, date, or address')
    end
  end

  validate :must_start_before_finish
  validates :finish, presence: true, if: "start.present?"
  def must_start_before_finish
    if start.present? && finish.present? && start > finish
      errors.add(:finish, 'must be after the start')
    end
  end

  before_validation do |event|
    event.finish = nil if event.start.blank?
    # don't allow saving with only one of lat, lng; must be neither or both
    event.lat = nil if event.lng.blank?
    event.lng = nil if event.lat.blank?
  end

  attr_accessor :notify_of_changes # setting to false allows supressing email notifications; todo: move to controller

  has_many :event_users, dependent: :destroy
  has_many :participants, through: :event_users, source: :user
  belongs_to :coordinator, class_name: 'User'
  def users
    people = participants.to_a
    people << coordinator if coordinator
    people
  end

  acts_as_mappable
  attr_accessor :no_geocode # force geocoding to not happen. used for testing
  after_validation :geocode, if: "!no_geocode && address_changed? && address.present? && (lat.blank? || lng.blank?)"
  validates :lat, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90}, allow_nil: true
  validates :lng, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180}, allow_nil: true

  default_scope { order :start }
  scope :past, -> { where('finish < ?', Time.zone.now).reorder('finish DESC') }
  scope :not_past, -> { where 'start IS NULL OR finish > ?', Time.zone.now }
  scope :not_attended_by, ->(user) { joins('LEFT JOIN event_users ON events.id = event_users.event_id').where("events.id NOT IN (SELECT event_id FROM event_users WHERE user_id = ?) AND coordinator_id != ?", user.id, user.id).distinct }
  scope :coordinatorless, -> { where coordinator: nil }
  scope :dateless, -> { where start: nil }
  scope :participatable, -> { where 'start IS NOT NULL AND coordinator_id IS NOT NULL AND status = ?', statuses[:approved] }
  scope :not_cancelled, -> { where 'status != ?', statuses[:cancelled] }
  scope :awaiting_approval, -> { not_past.where 'status = ? AND coordinator_id IS NOT NULL AND start IS NOT NULL', statuses[:proposed] }
  scope :in_month, ->(year, month) {
    month ||= ''
    year ||= ''
    unless (1..12).include?(month.to_i) && year.to_s.length == 4
      month = Time.zone.now.month
      year = Time.zone.now.year
    end
    start = Time.zone.parse "#{year}-#{month}-01"
    finish = month.to_i < 12 ? start.change(month: (start.month + 1)) : start.change(month: 1, year: (start.year + 1))
    where("start >= ? AND finish < ?", start, finish)
  }

  attr_reader :start_day, :start_time_12, :start_time_p
  attr_accessor :time_error
  before_validation do |event|
    errors.add(:base, 'Start time must be in the format ##:##') if event.time_error
  end
  def assign_attributes(attrs)
    # if inputing start in parts (day and time), then combine them
    start_day = attrs.delete(:start_day)
    start_time = attrs.delete(:start_time_12)
    if start_time.present? && !(start_time.strip =~ /1?[0-9](:[0-9]{2})?/)
      start_time = nil
      self.time_error = true
    end
    start_time_p = (attrs.delete(:start_time_p) || 'AM').upcase.gsub('.', '')
    attrs[:start] = "#{start_day} #{start_time} #{start_time_p}" if attrs[:start].blank? && start_day.present? && start_time.present?
    # this is needed because during mass assignment, we can't guarantee that :start will be set before :duration
    dur = attrs.delete(:duration)
    super(attrs)
    self.duration = dur
  end
  def start_time_12 # start time using 12-hour clock
    start.present? ? start.strftime('%l:%M') : nil
  end
  def start_time_p
    start.present? ? start.strftime('%p') : nil
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

  def awaiting_approval?
    !past? && proposed? && coordinator && start
  end

  include ActionView::Helpers::TextHelper # needed for truncate()
  def display_name
    return name if name.present?
    return truncate(description, length: 50, separator: ' ') if description.present?
    return truncate(address, length: 50, separator: ' ') if address.present?
    return start.strftime('%B %e %Y, %l:%M %p').gsub('  ', ' ') if start.present?
    '(untitled event)'
  end

  def participatable_by?(user)
    can_have_participants? && !past? && (user != coordinator) && user.has_role?(:participant) && status == 'approved'
  end

  def can_have_participants?
    start.present? && coordinator.present? && status != 'proposed'
  end

  def coords
    (lat.present? && lng.present?) ? [lat, lng] : nil
  end

  private

    def geocode
      geo = Geokit::Geocoders::MultiGeocoder.geocode address.gsub(/\n/, ', ')
      if geo.success
        self.lat, self.lng = geo.lat, geo.lng
      else
        errors.add(:address, 'Problem locating address')
      end
    end

end