class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  has_many :event_users
  has_many :events, through: :event_users

  has_many :roles
  after_create do |user|
   if user.class.count == 1
      user.roles.create name: Role.names[:admin]
    else
      user.roles.create name: Role.names[:participant]
    end
  end

  def display_name
    [:name, :email].each do |field|
      return self[field] if self[field].present?
    end
  end

end