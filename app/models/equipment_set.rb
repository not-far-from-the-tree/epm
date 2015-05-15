class EquipmentSet < ActiveRecord::Base
	has_many :events
	strip_attributes
end
