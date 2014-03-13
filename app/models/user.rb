class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  strip_attributes
  before_create do |user|
    if user.name.blank? && user.email.present? && user.email.include?('@')
      user.name = user.email.split('@').first.gsub(/\.|-|_/, ' ').titlecase
    end
    true
  end

  def self.csv
    CSV.generate force_quotes: true do |csv|
      csv << ['id', 'name', 'email', 'phone number', 'joined', 'events attended', 'roles', 'description']
      all.each do |user|
        csv << [user.id, user.name, user.email, user.phone, user.created_at.to_date.to_s, user.events.past.count, user.roles.map{|r| r.name}.join(', '), user.description]
      end
    end
  end

  scope :by_name, -> { order :name }
  scope :search, ->(q) {
    like = Rails.configuration.database_configuration[Rails.env]["adapter"] == 'postgresql' ? 'ILIKE' : 'LIKE'
    where("users.email LIKE ? OR users.name #{like} ?", "%#{q}%", "%#{q}%")
  }
  # todo: consider refactoring these to automatically have a scope for every role
  scope :admins, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:admin]}").distinct }
  scope :coordinators, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:coordinator]}").distinct }
  scope :participants, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:participant]}").distinct }

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
    name || '(no name)'
  end

  def avatar(size = :small)
    sizes = {small: 48, large: 80}
    "http://gravatar.com/avatar/#{CGI.escape(Digest::MD5.hexdigest(email.downcase))}?s=#{sizes[size]}&d=mm"
  end

end