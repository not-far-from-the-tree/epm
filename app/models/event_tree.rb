class EventTree < ActiveRecord::Base
  belongs_to :event
  belongs_to :tree
end
