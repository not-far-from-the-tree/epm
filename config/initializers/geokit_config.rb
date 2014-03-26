Geokit::Geocoders::NominatimGeocoder.server = 'open.mapquestapi.com/nominatim/v1/search'

Epm::Application.configure do
  config.geokit.default_units = :kms
  config.geokit.geocoders.provider_order = [:nominatim, :google]
end