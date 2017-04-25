# coding: utf-8
require './mapper.rb'
require './response.rb'
require './navigator.rb'

require 'pry'

class Rover
  POS_FORMAT = "%4.6f"

  def initialize(p=nil, _waypoints=[])
    @current_point = p
    @mapper = Mapper.new
    @nav = Navigator.new
    @waypoints = _waypoints
  end


  def lat
    @current_point.lat
  end
  def lon
    @current_point.lon
  end
  def bearing
    @current_point.bearing
  end
  def waypoint
    @current_point.waypoint
  end

  def waypoints
    @waypoints || []
  end

  def waypoints=(w)
    @waypoints = w
  end

  def current_target
    @waypoints.first
  end
  
  def point=(p)
    @current_point = p
  end

  def point
    @current_point
  end
  
  def status(opts=[])   
    pretty_name = @current_point.pretty_name
    
    output = [
      pretty_name,
      "lat: #{POS_FORMAT % lat}",
      "lon: #{POS_FORMAT % lon}",
      "bearing: #{bearing}°",
      @mapper.map_url(@current_point)
    ].compact.join(", ")

    @current_point = @current_point.increment

    Response.new(text:output, point: @current_point)
  end

  def map(opts=[])
    output = @mapper.map_url(@current_point)
    Response.new(text:output, point: @current_point)    
  end
  
  def left(opts=[])
    @current_point = @nav.left(point, opts)
    output = "turned to face #{@current_point.bearing}°"
    Response.new(text:output, point: @current_point)
  end

  def right(opts=[])
    @current_point = @nav.right(point, opts)
    output = "turned to face #{@current_point.bearing}°"
    Response.new(text:output, point: @current_point)
  end

  def turn(opts=[])
    @current_point = @nav.turn(point, opts)
    output = "turned to face #{@current_point.bearing}°"
    Response.new(text:output, point: @current_point)
  end

  def face(opts=[])
    @current_point = @nav.face(point, opts)
    output = "turned to face #{@current_point.bearing}°"
    Response.new(text:output, point: @current_point)
  end

  def move(opts=[])
    test_point = @nav.move(point, opts)
    r = Response.new(point: test_point)
    
    if r.valid?
      @current_point = test_point
      r.text = "moved #{test_point.speed} meters bearing #{test_point.bearing}°"
      r.valid = true

      handle_after_move
    else
      r.text = "Sorry, I can't move there"
      r.valid = false
    end

    r
  end

  def auto(opts=[])
    @nav.waypoint = current_target

    test_point = @nav.auto(point)
    r = Response.new(point: test_point)
    
    if r.valid?
      @current_point = test_point
      r.text = "moved #{test_point.speed} meters bearing #{test_point.bearing}°"
      r.valid = true

      handle_after_move
    else
      r.text = "I'm having some trouble picking a direction, please help!"
      r.valid = false
    end

    r
  end

  def repoint(opts=[])
    if current_target.nil?
      return Response.new(point: point,
                          text: "I don't have a destination to aim for!",
                          valid: false)
    end

    @nav.waypoint = current_target

    test_point = @nav.repoint(point)
    r = Response.new(point: test_point)
    
    if r.valid?
      @current_point = test_point
      t.text = "turned to face #{@current_point.bearing}°"
      r.valid = true

      handle_after_move
    else
      r.text = "I'm having some trouble picking a direction, please help!"
      r.valid = false
    end

    r
  end

  def target(opts=[])
    lat, lon, _when = opts
    return if lat.nil? || lat == ""

    if _when.nil?
      _when = "now"
    end

    lat = lat.to_f
    lon = lon.to_f

    p = Point.new(lat:lat, lon:lon)

    if _when == "now"
      @waypoints.unshift( p )
    else
      @waypoints = @waypoints.insert(-2, p)
    end

    new_dir = @nav.pick_direction(point)
    p1 = @current_point.increment
    p1.bearing = new_dir
    
    # @todo this is not great
    test_point = @nav.auto(p1)
    r = Response.new(point: test_point)
    
    if r.valid?
      @current_point = test_point
      r.text = "moved #{test_point.speed} meters bearing #{test_point.bearing}°"
      r.valid = true

      handle_after_move
    else
      r.text = "I'm having some trouble picking a direction, please help!"
      r.valid = false
    end

    r
  end

  def targets(opts=[])   
    output = waypoints.collect { |p|
      "#{p.lat},#{p.lon} #{@mapper.map_url(p)}"
    }.join("\n")

    Response.new(text:output, point: @current_point)
  end 

  def handle_after_move
    return if current_target.nil?
    if @nav.reached_waypoint?(point, current_target)
      @waypoints.shift
    end
  end
end
