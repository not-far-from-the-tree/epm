class GeocodeController < ApplicationController

  authorize_resource :class => false

  def index
    coords = nil
    if params['address'].present?
      geo = Geokit::Geocoders::MultiGeocoder.geocode params['address'].gsub(/\n/, ', ')
      coords = [geo.lat, geo.lng] if geo.success
    end
    render json: coords
  end

end