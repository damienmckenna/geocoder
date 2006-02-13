require 'test/unit'
require File.dirname(__FILE__) + '/../lib/geocoder'
require File.dirname(__FILE__) + '/mocks/http'

class TC_YahooGeocoderSuccess < Test::Unit::TestCase
  include Geocoder

  def setup
    @geocoder = Yahoo.new "YahooDemo"
    @response = @geocoder.geocode "2125 w north ave chicago il"
  end

  def test_success
    assert_equal true, @response.success?
  end

  def test_latitude
    assert_in_delta 41.910263, @response.latitude, 0.0005
  end

  def test_longitude
    assert_in_delta -87.680696, @response.longitude, 0.0005
  end

  def test_address
    assert_equal "2125 W NORTH AVE", @response.address
  end

  def test_city
    assert_equal "CHICAGO", @response.city
  end

  def test_state
    assert_equal "IL", @response.state
  end

  def test_zip
    assert_equal "60647-5415", @response.zip
  end

  def test_country
    assert_equal "US", @response.country
  end

  def test_street
    assert_respond_to @response, :street
    assert_same @response.street, @response.address
  end

  def test_lat
    assert_respond_to @response, :lat
    assert_same @response.lat, @response.latitude
  end

  def test_lng
    assert_respond_to @response, :lng
    assert_same @response.lng, @response.lng
  end
end

class TC_YahooGeocoderAmbiguous < Test::Unit::TestCase
  include Geocoder

  def setup
    @geocoder = Yahoo.new "YahooDemo"
    @response = @geocoder.geocode "2038 damen ave chicago il"
  end

  def test_success
    assert_equal false, @response.success?
  end

  def test_matches
    assert_equal 2, @response.size
  end

  def test_warning
    @response.each do |result|
      assert_match %r{^The exact location could not be found, here is the closest match:},
        result.warning
    end
  end

  def test_precision
    @response.each do |result|
      assert_equal "address", result.precision
    end
  end
end

class TC_YahooGeocoderErrors < Test::Unit::TestCase
  include Geocoder

  def setup
    @geocoder = Yahoo.new "YahooDemo"
  end

  def test_nil_location
    @response = @geocoder.geocode nil
    assert !@response.success?
    assert @response.error?
    assert_equal "unable to parse location", @response.reasons[0]
  end
  
  def test_empty_string_location
    @response = @geocoder.geocode ""
    assert !@response.success?
    assert @response.error?
    assert_equal "unable to parse location", @response.reasons[0]
  end
  
  def test_throws_on_ungeocodeable
    @response = @geocoder.geocode "donotleaveitisnotreal"
    assert !@response.success?
    assert @response.error?
    assert_equal "unable to parse location", @response.reasons[0]
  end
end
