class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  has_many :event_users
  has_many :events, through: :event_users

  def display_name
    [:name, :email].each do |field|
      return self[field] if self[field].present?
    end
  end

end