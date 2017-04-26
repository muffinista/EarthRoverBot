# coding: utf-8
class Navigator
  AUTO_MOVE_ATTEMPTS = 8
  DEFAULT_MOVE = 400
  MIN_WAYPOINT_DISTANCE = 25
  MAX_MOVE = 1000
  AUTO_SPEEDS = [200, 150, 100, 75, 50, 40, 30, 20, 10, 5]
  
  attr_accessor :waypoint
  
  def initialize
    @sv_checker = StreetViewChecker.new
  end
  
  def valid_street_map?(tmpurl)
    @sv_checker.valid_street_map?(tmpurl)
  end

  
  def turn(point, opts = [])
    opts << 45
    STDERR.puts "TURN #{opts.inspect}"
    dir = opts.select { |i| i.to_i != 0 }.first.to_i

    p = point.increment(bearing: point.bearing + dir)
    p.valid?
    p
  end

  def repoint(point, opts = [])
    point.increment(bearing: destination_bearing(point))
  end

  def face(point, opts = [])
    opts << 0
    STDERR.puts opts.inspect
    dir = opts.first.to_i

    dir = Point.normalize_angle(dir)
    p = point.increment(bearing: dir)
    p.valid?
    p
  end
  
  def left(point, opts = [])
    opts << 45
    dir = opts.select { |i| i.to_i != 0 }.first
    dir = dir.to_i * -1
    
    turn(point, [dir])
  end

  def right(point, opts = [])
    opts << 45
    dir = opts.select { |i| i.to_i != 0 }.first

    turn(point, [dir])
  end

  def auto(point, opts=[])
    r = nil

    opts = (5..250).step(10).to_a

    max_move = nil

    bad_moves = 0
    # go from low to high until we've made too many bad moves
    opts.each { |dist|
      if bad_moves < AUTO_MOVE_ATTEMPTS
        r = move(point, [dist])
        if r.valid?
          max_move = r
        else
          bad_moves = bad_moves + 1
        end
      end
    }

    return max_move if !max_move.nil?

    STDERR.puts "unable to move without turning"
    new_dir = pick_direction(point)
    new_dir
  end

  
  def pick_direction(p)
    new_p = retarget_from(p, p.bearing, true)

    # start from scratch if a narrow attempt didnt work
    new_p ||= retarget_from(p)

    new_p
  end

  
  def retarget_from(point, base=nil, tight=false)
    if base.nil?
      STDERR.puts "get bearing from point to waypoint"
      base = destination_bearing(point)
    end

    STDERR.puts "retarget #{base} #{tight}"

    # we basically either sweep left or right randomly here
    if rand > 0.5
      offset = 1
      mult = -1
    else
      offset = -1
      mult = 1
    end

    arcs = [
            { start: 20 * mult, offset: offset, max_steps: 40 },
            { start: 40 * mult, offset: offset, max_steps: 80 },
            { start: 60 * mult, offset: offset, max_steps: 120 },
            { start: 45 * mult, offset: offset, max_steps: 360 }
           ]

    # limit to a smaller arc
    if tight == true
      arcs = arcs.reject { |a|
        a[:max_steps] > 80
      }
    end

    test = point.increment

    arcs.each { |opts|
      start = opts[:start]
      offset = opts[:offset]
      max_steps = opts[:max_steps]

      STDERR.puts "PICK DIRECTION, starting at #{base} + #{start}"
      test.bearing = base + start
      steps = 0

      while steps <= max_steps && steps >= -1 * max_steps
        test.bearing += steps

        AUTO_SPEEDS.each { |test_speed|
          test.speed = test_speed
          result = test.move

          if result.valid?
            STDERR.puts "looks like #{test} works"
            return test
          end
        }
        
        steps = steps + offset
      end
    }

    nil
  end

  
  # http://stackoverflow.com/questions/2187657/calculate-second-point-knowing-the-starting-point-and-distance
  def move(point, opts = [])
    opts << DEFAULT_MOVE
    
    d = opts.select { |i| i.to_i > 0 }.first
    # d = opts.select { |i| i =~ /\A[-+]?\d+\z/  }.first.to_i

    d = DEFAULT_MOVE if d == 0
    d = d.to_i
    
    if opts.join(" ") =~ /forward/
      
    elsif opts.join(" ") =~ /back/
      d *= -1
    end
    
    if d > MAX_MOVE
      d = MAX_MOVE
    elsif d < -MAX_MOVE
      d = -MAX_MOVE
    end

    p = point.increment
    p.move(d)   
  end

  def distance_to_waypoint(p, wp)
    lat1 = p.lat * Math::PI / 180.to_f
    lon1 = p.lon * Math::PI / 180.to_f
    
    lat2 = wp.lat.to_f * Math::PI / 180.to_f
    lon2 = wp.lon.to_f * Math::PI / 180.to_f

    r = 6371000 # radius of earth in meters

    dLat = lat2 - lat1
    dLon = lon2 - lon1
    
    a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1) * Math.cos(lat2) * 
      Math.sin(dLon/2) * Math.sin(dLon/2)

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
    distance = r * c
  end

  def reached_waypoint?(p, wp)
    dist = distance_to_waypoint(p, wp)
    STDERR.puts "DISTANCE TO WAYPOINT: #{dist} meters"
    if dist.abs < MIN_WAYPOINT_DISTANCE
      true
    else
      false
    end
  end
  
  def destination_bearing(point, wp=@waypoint)
    # http://www.movable-type.co.uk/scripts/latlong.html
    # JavaScript:
    # var y = Math.sin(λ2-λ1) * Math.cos(φ2);
    # var x = Math.cos(φ1)*Math.sin(φ2) -
    #         Math.sin(φ1)*Math.cos(φ2)*Math.cos(λ2-λ1);
    # var brng = Math.atan2(y, x).toDegrees();
    # φ is latitude, λ is longitude,

    STDERR.puts "SOURCE: #{point.inspect}"
    STDERR.puts "TARGET: #{wp.inspect}"

    lat2 = wp.lat.to_f * Math::PI / 180.to_f
    lon2 = wp.lon.to_f * Math::PI / 180.to_f

    lat1 = point.lat.to_f * Math::PI / 180.to_f
    lon1 = point.lon.to_f * Math::PI / 180.to_f

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
