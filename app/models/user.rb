class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  strip_attributes

  attr_accessor :signed_waiver
  validates :signed_waiver, acceptance: true, if: :new_record?

  validates :email, :fname, :lname, :phone, presence: true

  def self.csv(users)
    CSV.generate force_quotes: true do |csv|
      csv << ['id', 'first name', 'last name', 'email', 'phone number', 'address', 'allow snail mail', 'joined', "events attended as #{Configurable.participant.indefinitize}", 'roles']
      users.each do |user|
        csv << [user.id, user.fname, user.lname, user.email, user.phone, user.address, user.snail_mail, user.created_at.to_date.to_s, user.num_participated_events, user.roles.map{|r| Configurable.send(r.name)}.join(', ')]
      end
    end
  end

  # this section identical to that in model event.rb
  acts_as_mappable
  attr_accessor :no_geocode # force geocoding to not happen. used for testing
  after_validation :geocode, if: "!no_geocode && address_changed? && address.present? && (lat.blank? || lng.blank?)"
  validates :lat, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90}, allow_nil: true
  validates :lng, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180}, allow_nil: true

  has_many :user_wards
  has_many :wards, through: :user_wards

  scope :by_name, -> { order :lname, :fname }
  scope :geocoded, -> { where.not lat: nil }
  scope :search, ->(q) {
    db = Rails.configuration.database_configuration[Rails.env]["adapter"]
    like = db == 'postgresql' ? 'ILIKE' : 'LIKE'
    name = db ==  'mysql2' ? "CONCAT(users.fname, ' ', users.lname)" : "(users.fname || ' ' || users.lname)"
    where("users.email #{like} ? OR #{name} #{like} ?", "%#{q}%", "%#{q}%")
  }
  scope :roleless, -> { where 'users.id NOT IN (SELECT DISTINCT user_id FROM roles)' }
  # todo: consider refactoring these to automatically have a scope for every role
  scope :admins, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:admin]}") }
  scope :coordinators, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:coordinator]}") }
  scope :participants, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:participant]}") }
  def self.coordinators_not_taking_attendance
    # get the ids of events needing attendance taken and more 3 days old (note: query is executed as a subquery of the next query)
    event_ids = Event.needing_attendance_taken.where("finish < ?", 3.days.ago).reorder(nil).select 'events.id'
    # get the coordinators of those events, orderded by how many events they haven't done attendance for
    coordinator_ids = Event.where("id IN (#{event_ids.to_sql})").group(:coordinator_id).reorder('COUNT(events.id) DESC').select(:coordinator_id).pluck :coordinator_id
    coordinators = User.where(id: coordinator_ids).to_a
    coordinator_ids.map{|uid| coordinators.find{|c| c.id == uid} }
  end
  scope :not_involved_in, ->(event) { where.not "users.id IN (#{EventUser.where(event_id: event.id).select(:user_id).to_sql})" }
  scope :interested_in_ward, ->(ward) { joins("INNER JOIN user_wards ON user_wards.user_id = users.id AND user_wards.ward_id = #{ward.id}") }
  scope :invitable_to, ->(event) {
    return none unless event.ward
    participants.interested_in_ward(event.ward).not_involved_in(event)
  }
  scope :no_shows, -> {
    joins("INNER JOIN event_users ON event_users.user_id = users.id AND event_users.status = #{EventUser.statuses[:no_show]}")
      .group('users.id')
      .reorder('MAX(event_users.updated_at) DESC, COUNT(users.id)')
  }
  def no_show_count
    event_users.where(status: EventUser.statuses[:no_show]).count
  end

  has_many :event_users, dependent: :destroy
  has_many :coordinating_events, -> { where.not(status: Event.statuses[:cancelled]) }, class_name: 'Event', foreign_key: 'coordinator_id'
  has_many :participated_events, -> { # events where a user was marked as having attended (and thus in the past and not cancelled)
      where('event_users.status' => EventUser.statuses[:attended]).where('events.status = ?', Event.statuses[:approved])
    }, through: :event_users, source: :event
  def events # where the user is a participant or the coordinator
    Event.not_cancelled
      .joins("LEFT JOIN event_users ON events.id = event_users.event_id AND event_users.status IN (#{EventUser.statuses_array(:attending, :attended).join(', ')})")
      .where("events.coordinator_id = ? OR event_users.user_id = ?", id, id)
      .distinct
  end
  def open_invites # upcoming events the user has been invited to
    Event.not_past.not_cancelled.joins(:event_users)
      .where(
        'event_users.status' => EventUser.statuses[:invited],
        'event_users.user_id' => id
      )
  end
  def potential_events # upcoming events where waitlisted or requested to attend
    Event.not_past.not_cancelled.joins(:event_users)
      .where(
        'event_users.status' => EventUser.statuses_array(:waitlisted, :requested),
        'event_users.user_id' => id
      )
  end
  def participating_events # upcoming events the participant plans to attend
    Event.not_past.not_cancelled.joins(:event_users)
      .where(
        'event_users.status' => EventUser.statuses[:attending],
        'event_users.user_id' => id
      )
  end

  has_many :roles, dependent: :destroy
  accepts_nested_attributes_for :roles
  attr_accessor :no_roles
  after_create :set_default_role, if: "roles.empty? && !no_roles"
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
  def has_any_role?(*roles)
    roles.each do |role|
      return true if has_role?(role)
    end
    false
  end

  def display_name
    n = "#{fname} #{lname}".strip
    n.present? ? n : '(no name given)'
  end

  def avatar(size = :small)
    sizes = {small: 48, large: 80}
    "http://gravatar.com/avatar/#{CGI.escape(Digest::MD5.hexdigest(email.downcase))}?s=#{sizes[size]}&d=mm"
  end

  def ability # allows checking permissions for this user rather than the current
    @ability ||= Ability.new(self)
  end

  def add_to_mailing_list # note: does not first check whether user is already on the mailing list
    return false unless self.valid? && email.present?
    return true unless Rails.env.production? # temporary solution to avoiding API calls
    Gibbon::API.throws_exceptions = false
    gb = Gibbon::API.new(ENV['mailing_list_api_key'])
    resp = gb.lists.subscribe( # http://apidocs.mailchimp.com/api/2.0/lists/subscribe.php
        id: ENV['mailing_list_id'],
        email: {email: email},
        merge_vars: {:FNAME => fname, :LNAME => lname},
        double_optin: false,
        send_welcome: true
      )
    !resp['email'].nil? && resp['status'] != 'error'
  end

  def coords
    (lat.present? && lng.present?) ? [lat, lng] : nil
  end

  private

    # this method identical to that in model event.rb
    def geocode
      geo = Geokit::Geocoders::MultiGeocoder.geocode address.gsub(/\n/, ', ')
      if geo.success
        self.lat, self.lng = geo.lat, geo.lng
      else
        errors.add(:address, 'Problem locating address')
      end
    end


end