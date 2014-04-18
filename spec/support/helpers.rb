module Helpers

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def map_points
    all('.map .leaflet-marker-icon').length
  end

end