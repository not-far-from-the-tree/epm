class Agency < ActiveRecord::Base
	has_many :events
	strip_attributes

	validates :title, :presence => true
end
