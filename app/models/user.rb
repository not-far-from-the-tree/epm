class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  strip_attributes

  scope :search, ->(q) { where("users.email LIKE ? OR users.name LIKE ?", "%#{q}%", "%#{q}%") }
  # todo: consider refactoring these to automatically have a scope for every role
  scope :participants, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:participant]}").distinct }
  scope :coordinators, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:coordinator]}").distinct }

  has_many :event_users, dependent: :destroy
  has_many :participating_events, through: :event_users, source: :event
  has_many :coordinating_events, class_name: 'Event', foreign_key: 'coordinator_id'
  def events # events where the user is a participant or the coordinator
    Event.joins("LEFT JOIN event_users ON events.id = event_users.event_id").where("events.coordinator_id = ? OR event_users.user_id = ?", id, id).distinct
  end

  has_many :roles, dependent: :destroy
  accepts_nested_attributes_for :roles
  after_create :set_default_role, if: "roles.empty?"
  def set_default_role
   if self.class.count == 1
      self.roles.create name: :admin
    else
      self.roles.create name: :participant
    end
  end
  def has_role?(role_name)
    !self.roles.find{|r| r.send "#{role_name}?" }.nil?
  end

  def display_name
    [:name, :email].each do |field|
      return self[field] if self[field].present?
    end
  end

end