require 'geocoder'
geocoder = Geocoder::Yahoo.new "my_app_id" # =>
result = geocoder.geocode "2038 damen ave chicago il"
result.success? # =>
result.each do |r|
  r.lat # =>
  r.lng # =>
  r.address # =>
  r.city # =>
  r.state # =>
  r.zip # =>
end
