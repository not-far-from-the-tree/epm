class Tree < ActiveRecord::Base
  acts_as_mappable
  attr_accessor :no_geocode # force geocoding to not happen. used for testing
  after_validation :geocode, if: "!no_geocode && address_changed? && address.present? && (lat.blank? || lng.blank?)"
  validates :lat, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90}, allow_nil: true
  validates :lng, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180}, allow_nil: true
  def coords
    (lat.present? && lng.present?) ? [lat, lng] : nil
  end

  private
	 # this method identical to that in model user.rb
	def geocode
	  geo = Geokit::Geocoders::MultiGeocoder.geocode address.gsub(/\n/, ', ')
	  self.lat, self.lng = geo.lat, geo.lng if geo.success
	end

end
