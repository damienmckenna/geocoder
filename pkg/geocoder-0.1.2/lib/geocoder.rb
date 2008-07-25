#--
# Copyright (c) 2006 Paul Smith <paul@cnt.org>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#
# = Geocoder -- Geocoding library for Ruby
#
require 'cgi'
require 'net/http'
require 'rexml/document'
require 'timeout'

module Geocoder

  class GeocodingError < Exception; end

  FIELDS = [ ["latitude", "Latitude"],
             ["longitude", "Longitude"],
             ["address", "Address"],
             ["city", "City"],
             ["state", "State"], 
             ["zip", "ZIP Code"] ].freeze

  class Base
    # +location+ is a string, any of the following:
    # * city, state
    # * city, state, zip
    # * zip
    # * street, city, state
    # * street, city, state, zip
    # * street, zip
    def geocode location, *args
      options = { :timeout => nil }
      options.update(args.pop) if args.last.is_a?(Hash)
      @options = options
      location = String location
      response = parse request(location)
    end

    # Makes an HTTP GET request on URL and returns the body
    # of the response
    def get url, timeout=5
      url = URI.parse url
      http = Net::HTTP.new url.host, url.port
      res = Timeout::timeout(timeout) {
        http.get url.request_uri
      }
      res.body
    end

    def request location
      get url(location), @options[:timeout]
    end
  end

  class GeoCoderUs < Base
    def initialize *args
      #
    end

    private

    def parse csv_text
      if csv_text =~ /^2: /
        return Response.new(GeocodingError.new(csv_text.split(": ")[1]))
      elsif csv_text =~ /please supply an address/
        return Response.new(GeocodingError.new(["please supply an address"]))
      end
      results = []
      csv_text.split("\n").each do |line|
        latitude, longitude, address, city, state, zip = line.split ","
        result = Result.new
        result.latitude = latitude
        result.longitude = longitude
        result.address = address
        result.city = city
        result.state = state
        result.zip = zip
        results << result
      end
      response = Response.new results
    end

    # Returns URL of geocoder.us web service
    def url address
      "http://rpc.geocoder.us/service/csv?address=#{CGI.escape address}"
    end
  end

  class Yahoo < Base
    include REXML
    # Requires a Y! Application ID
    # http://developer.yahoo.net/faq/index.html#appid
    def initialize appid
      @appid = appid
    end

    private

    # return array of results
    def parse xml
      # Create a new REXML::Document object from the raw XML text
      xml = Document.new xml
      # 
      # Normally, Y! will return an XML document with the root node
      # <ResultSet>; if the request bombs, they return one with the
      # root node <Error>
      if is_error? xml
        msgs = []
        xml.root.elements.each("Message") { |e| msgs << e.get_text.value }
        response = Response.new GeocodingError.new(msgs)
        return response
      else
        results = []
        xml.root.elements.each "Result" do |e|
          result = Result.new
          # add fields
          fields.each do |field|
            text = e.elements[field.capitalize].get_text
            if text.respond_to? :value
              result.send "#{field}=", text.value
            end
          end
          # add attributes
          attributes.each do |attribute|
            result.send "#{attribute}=", e.attributes[attribute]
          end
          results << result
        end
        response = Response.new results
      end
    end

    def fields
      %w| latitude longitude address city state zip country |
    end

    def attributes
      %w| precision warning |
    end

    def is_error? document
      document.root.name == "Error"
    end

    # Returns URL of Y! Geocoding web service
    def url location
      "http://api.local.yahoo.com/MapsService/V1/geocode?appid=#{@appid}&location=#{CGI.escape location}"
    end
  end

  SERVICES = { :yahoo => Yahoo,
               :geocoderus => GeoCoderUs }.freeze

  class GeocodingError
    attr_accessor :reasons
    def initialize reasons=[]
      @reasons = reasons
    end
  end

  class Result < Struct.new :latitude, :longitude, :address, :city,
                            :state, :zip, :country, :precision,
                            :warning
    alias :lat :latitude
    alias :lng :longitude
    alias :street :address
  end

  # A Response is a representation of the entire response from the
  # Y! Geocoding web service, which may include multiple results,
  # as well as warnings and errors
  class Response < Array
    def initialize results
      if results.is_a? GeocodingError
        @success = false
        @error = true
        @reasons = results.reasons
      else
        @success = true
        results.each do |result|
          self << result
        end
      end
    end

    def success?
      @success and self[0].warning.nil?
    end

    def error?
      @error
    end

    def reasons
      @reasons
    end

    def bullseye?
      success?
    end

    # Returns latitude in degrees decimal
    def latitude
      self[0].latitude if bullseye?
    end

    # Returns longitude in degrees decimal
    def longitude
      self[0].longitude if bullseye?
    end

    # Returns normalized street address, capitalized
    def address
      self[0].address if bullseye?
    end

    # Returns normalized city name, capitalized
    def city
      self[0].city if bullseye?
    end

    # Returns normalized two-letter USPS state abbreviation
    def state
      self[0].state if bullseye?
    end

    alias_method :array_zip, :zip
   
    # Returns normalized ZIP Code, or postal code
    def zip
      self[0].zip if bullseye?
    end

    # Returns two-letter country code abbreviation
    def country
      self[0].country if bullseye?
    end

    alias :lat :latitude
    alias :lng :longitude
    alias :street :address
  end

  class Cli
    require 'optparse'
    require 'ostruct'

    def self.parse args
      options = OpenStruct.new
      # default values
      options.appid = "YahooDemo"
      options.service = Yahoo
      options.timeout = 5
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: geocode [options] location"
        opts.separator ""
        opts.separator "Options:"
        opts.on "-a appid", "--appid appid", "Yahoo! Application ID" do |a|
          options.appid = a
        end
        opts.on "-s service", "--service service", "`yahoo' or `geocoderus'" do |s|
          options.service = SERVICES[s]
        end
        opts.on "-t secs", "--timeout secs", Integer, "Timeout in seconds" do |t|
          options.timeout = t
        end
        opts.on "-q", "--quiet", "Quiet output" do |q|
          options.quiet = q
        end
        opts.on_tail "-h", "--help", "Show this message" do
          puts opts
          exit
        end
        opts.parse! args
      end
      [options, opts]
    end

    def initialize cli_args
      @options, @opt_parser = Cli::parse cli_args
      @location = cli_args.join " "
    end

    def report result
      buffer = []
      if @options.quiet
        result.each do |r|
          buffer << FIELDS.collect do |k,v|
            r.send k
          end.join(",")
        end
      else
        buffer << "Found #{result.size} result(s)."
        buffer << buffer.last.gsub(/./, "-")
        buffer << result.collect do |r|
          FIELDS.collect do |k,v|
            "#{v}: #{r.send k}"
          end.join("\n")
        end.join("\n- - - -\n")
      end
      puts buffer.join("\n")
    end

    def go!
      g = @options.service.new @options.appid
      begin
        result = g.geocode @location, :timeout => @options.timeout
        report result
      rescue BlankLocationString
        STDERR.puts "You have to give an address to geocode!"
        puts
        puts @opt_parser
        exit
      rescue Timeout::Error
        STDERR.puts "The remote geocoding service timed-out. Try increasing the timeout value (-t)."
        exit
      rescue Geocoder::GeocodingError => e
        STDERR.puts "Geocoder: #{e}"
        exit
      end
    end
  end
end
