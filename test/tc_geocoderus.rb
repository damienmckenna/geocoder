require 'test/unit'
require File.dirname(__FILE__) + '/../lib/geocoder'
require File.dirname(__FILE__) + '/mocks/http'

class TC_GeoCoderUsSuccess < Test::Unit::TestCase
  include Geocoder

  def setup
    @geocoder = GeoCoderUs.new
    @response = @geocoder.geocode "2125 w north ave chicago il"
  end

  def test_success
    assert_equal true, @response.success?
  end

  def test_latitude
    assert_in_delta 41.910408, @response.latitude, 0.0005
  end

  def test_longitude
    assert_in_delta -87.680592, @response.longitude, 0.0005
  end

  def test_address
    assert_equal "2125 W North Ave", @response.address
  end

  def test_city
    assert_equal "Chicago", @response.city
  end

  def test_state
    assert_equal "IL", @response.state
  end

  def test_zip
    assert_equal "60647", @response.zip
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

class TC_GeoCoderUsAmbiguous < Test::Unit::TestCase
  include Geocoder

  def setup
    @geocoder = GeoCoderUs.new
    @response = @geocoder.geocode "2038 damen ave chicago il"
  end

  def test_success
    assert_equal true, @response.success?
  end

  def test_matches
    assert_equal 2, @response.size
  end

  def test_warning
    @response.each do |result|
      assert_nil result.warning
    end
  end

  def test_precision
    @response.each do |result|
      assert_nil result.precision
    end
  end
end

class TC_GeoCoderUsErrors < Test::Unit::TestCase
  include Geocoder

  def setup
    @geocoder = GeoCoderUs.new
  end

  def test_nil_location
    @response = @geocoder.geocode nil
    assert !@response.success?
    assert @response.error?
  end
  
  def test_empty_string_location
    @response = @geocoder.geocode ""
    assert !@response.success?
    assert @response.error?
  end
  
  def test_throws_on_ungeocodeable
    @response = @geocoder.geocode "donotleaveitisnotreal"
    assert !@response.success?
    assert @response.error?
  end
end
