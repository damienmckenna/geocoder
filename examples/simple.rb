require 'geocoder'
geocoder = Geocoder::Yahoo.new "my_app_id" # =>
result = geocoder.geocode "1600 pennsylvania ave nw washington dc"
result.lat # =>
result.lng # =>
result.address # =>
result.city # =>
result.state # =>
result.zip # =>
