class Event < ActiveRecord::Base

  validates :start, :finish, presence: true

end
