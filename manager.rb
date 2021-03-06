#
# This class mostly handles loading/persisting data
#
class Manager
  LOGFILE = "log.json"
  DATAFILE = "data.json"
  WAYPOINTS = "waypoints.json"
  
  def initialize
    @rover = Rover.new
    load
  end

  def current_point
    @rover.point
  end

  def rover
    @rover
  end

  def load(filename="data.json")
    if File.exist?(filename)
      file = File.read(filename)
      h = JSON.parse(file)

      apply(h)
    end
  end

  def apply(h)
    @rover.point = Point.new(h["point"])
    @rover.waypoints = h["waypoints"].collect { |x| Point.new(x) } || []
  end

  def save(filename=DATAFILE)
    data = {
      "point" => @rover.point.to_h,
      "waypoints" => @rover.waypoints.collect(&:to_h)
    }

    File.write(filename, JSON.dump(data))
    data
  end

  def update_log(request, result)
    output = {
      "request" => request.to_h,
      "result" => result.to_h
    }

    output = JSON.dump(output)
    
    f = File.open(LOGFILE, "a")
    f.puts output
    f.close

    # update waypoints too
    if result.point
      output = result.point.to_h
      output = JSON.dump(output)
      
      f = File.open(WAYPOINTS, "a")
      f.puts output
      f.close
    end

  end 
end
