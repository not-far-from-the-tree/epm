class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  has_many :event_users, dependent: :destroy
  has_many :events, through: :event_users

  has_many :roles, dependent: :destroy
  attr_accessor :no_roles
  after_create :set_default_role, unless: :no_roles
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