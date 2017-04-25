require 'httparty'
require 'pry'

class Mapper
  BASE_URL = "https://maps.googleapis.com/maps/api/streetview"
  FOV = 100
  SIZE="640x640"
  
  def url(point)
    "#{BASE_URL}?key=#{ENV['GOOGLE_API_KEY']}&fov=#{FOV}&size=#{SIZE}&heading=#{point.bearing}&location=#{point.lat},#{point.lon}"
  end

  def map_url(point)
    "https://maps.google.com/?t=k&q=#{point.lat},#{point.lon}"
  end

  def place_from_position(point)
    tmpurl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{point.lat},#{point.lon}"

    data = HTTParty.get(tmpurl)
    return nil if ! data["results"]

    best = data["results"].find { |d|
      d["types"].find { |t| ["locality", "natural_feature", "route", "colloquial_area"].include?(t) } != nil
    }

    if best.nil?
      best = data["results"].find { |d|
        d["formatted_address"] && !d["types"].include?('street_address')
      }
    end

    return if best.nil?
    return best["formatted_address"].gsub(/ USA/, "").gsub(/,$/, "")
  end
end
