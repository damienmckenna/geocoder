require 'test/unit'
%w{ tc_yahoo tc_geocoderus }.each { |tc|
  require File.dirname(__FILE__) + "/#{tc}"
}
