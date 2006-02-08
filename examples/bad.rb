require 'geocoder'
geocoder = Geocoder::Yahoo.new "my_app_id" # =>
begin
  result = geocoder.geocode "thisisnotreal"
rescue Geocoder::GeocodingError
  # do something appropriate to your application here
end
