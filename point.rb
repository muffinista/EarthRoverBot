# coding: utf-8
require 'fileutils'
require './json_struct.rb'
require './mapper.rb'

# step
# lat
# lon
# bearing
# speed

class Point < JSONStruct
  IMAGE_PATH = "images"
  IMAGE_PADDING = 8
  
  class << self
    def default_point
      Point.new(
        step: 0,
        lat: 0.0,
        lon: 0.0,
        bearing: 0,
        speed: 0
      )
    end

    #
    # take an angle and update it to be from 0-360
    #
    def normalize_angle(a)
      while a < 0 do
        a = a + 360
      end
      while a > 360 do
        a = a - 360
      end
      
      a
    end
  end

  def increment(attrs={})
    p = Point.new(
      step: self.step + 1,
      lat: self.lat,
      lon: self.lon,
      bearing: self.bearing,
      speed: self.speed
    )

    attrs.each { |k, v|
      p[k] = v
    }

    p
  end


  def mapper
    @_mapper ||= Mapper.new
  end
  
  def url
    mapper.url(self)
  end

  def pretty_name
    mapper.place_from_position(self)
  end

  def filename
    self.step.to_s.rjust(IMAGE_PADDING, '0')
  end
  
  def image_dir
    subdirs = filename.chars.each_slice(3).map(&:join).first(2)
    File.join(IMAGE_PATH, subdirs)
  end
  
  def image_path
    File.join(image_dir, "#{filename}.jpg")
  end
  
  #
  # is this a valid location on google street view?
  # NOTE: if it is valid, the block here will copy the temp file
  # we use for testing to display to the user later
  # 
  def valid?
    svc = StreetViewChecker.new
    svc.valid_street_map?(self.url) { |file|
      FileUtils.mkdir_p(image_dir)
      FileUtils.cp(file, image_path)
    }
  end

  #
  # get the string we'll use to identify a waypoint in tweets
  #
  def current_waypoint
    self.step.to_s(36)    
  end

  def bearing=(x)
    if x.is_a?(Point)
      x = x.bearing
    end
    self[:bearing] = Point.normalize_angle(x)
  end

  def move(dist=speed)
    # Formula:	φ2 = asin( sin φ1 ⋅ cos δ + cos φ1 ⋅ sin δ ⋅ cos θ )
    # λ2 = λ1 + atan2( sin θ ⋅ sin δ ⋅ cos φ1, cos δ − sin φ1 ⋅ sin φ2 )
    # where	φ is latitude, λ is longitude, θ is the bearing (in
    # radians, clockwise from north),
    # δ is the angular distance (in radians) d/R; d being the distance
    # travelled, R the earth’sradius

    #http://stackoverflow.com/questions/7222382/get-lat-long-given-current-point-distance-and-bearing
    
    r = 6378.1 #radius of the Earth
    d = dist.to_f / 1000

    lat1 = self.lat * Math::PI / 180.to_f
    lon1 = self.lon * Math::PI / 180.to_f
    
    rad_bearing = self.bearing * Math::PI / 180.to_f
    
    lat2 = Math.asin( Math.sin(lat1)*Math.cos(d/r) +
                      Math.cos(lat1)*Math.sin(d/r)*Math.cos(rad_bearing))
    
    lon2 = lon1 + Math.atan2(Math.sin(rad_bearing)*Math.sin(d/r)*Math.cos(lat1),
                             Math.cos(d/r)-Math.sin(lat1)*Math.sin(lat2))

    new_point = self.increment
    new_point.lat = lat2 * 180.to_f / Math::PI
    new_point.lon = lon2 * 180.to_f / Math::PI
    new_point.speed = dist
    new_point
  end
  
  def bearing_to(lat, lon)
    # http://www.movable-type.co.uk/scripts/latlong.html
    # JavaScript:	
    # var y = Math.sin(λ2-λ1) * Math.cos(φ2);
    # var x = Math.cos(φ1)*Math.sin(φ2) -
    #         Math.sin(φ1)*Math.cos(φ2)*Math.cos(λ2-λ1);
    # var brng = Math.atan2(y, x).toDegrees();
    # φ is latitude, λ is longitude,

    lat2 = lat.to_f * Math::PI / 180.to_f
    lon2 = lon.to_f * Math::PI / 180.to_f

    lat1 = self.lat * Math::PI / 180.to_f
    lon1 = self.lon * Math::PI / 180.to_f

    # http://gis.stackexchange.com/questions/29239/calculate-bearing-between-two-decimal-gps-coordinates
    dLong = lon2 - lon1
    dPhi = Math.log(Math.tan(lat2 / 2.0 + Math::PI/4.0) / Math.tan(lat1/2.0 + Math::PI / 4.0))
    if dLong.abs > Math::PI
      if dLong > 0.0
        dLong = -(2.0 * Math::PI - dLong)
      else
        dLong = (2.0 * Math::PI + dLong)
      end
    end

    brng = Math.atan2(dLong, dPhi)

    brng = (brng * 180.to_f / Math::PI).to_i
    brng = Point.normalize_angle(brng)
  end
end
