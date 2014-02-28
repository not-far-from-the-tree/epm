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
  belongs_to :coordinator, class_name: 'User'

  default_scope { order :start }
  scope :past, -> { where('finish < ?', Time.zone.now).order('finish DESC') }
  scope :not_past, -> { where 'finish > ?', Time.zone.now }
  # for not_attended_by, not sure why coordinator_id needs a separate null check. is this just a sqlite thing?
  scope :not_attended_by, ->(user) { joins('LEFT JOIN event_users ON events.id = event_users.event_id').where("events.id NOT IN (SELECT event_id FROM event_users WHERE user_id = ?) AND (coordinator_id IS NULL OR coordinator_id != ?)", user.id, user.id).distinct }
  scope :coordinatorless, -> { where(coordinator: nil) }
  scope :participatable, -> { where("start IS NOT NULL").where("coordinator_id IS NOT NULL") }

  def past?
    @is_past ||= finish < Time.zone.now
  end

  include ActionView::Helpers::TextHelper # needed for truncate()
  def display_name
    return name if name.present?
    return truncate(description, length: 50, separator: ' ') if description.present?
    return self.when if start.present? && finish.present?
    '(untitled event)'
  end

  def when
    "#{start.strftime '%B %e %Y, %l:%M %p'} to #{finish.strftime '%B %e %Y, %l:%M %p'}".gsub('  ', ' ')
  end

  def participatable_by?(user)
    can_have_participants? && !past? && (user != coordinator) && user.has_role?(:participant)
  end

  def can_have_participants?
    start.present? && coordinator.present?
  end

end