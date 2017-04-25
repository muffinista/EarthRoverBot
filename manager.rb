require 'sequel'

class Manager
  LOGFILE = "log.json"
  DATAFILE = "data.json"

  def initialize
    @bot = Bot.new
    load
  end

  def current_point
    @bot.point
  end

  def bot
    @bot
  end

  def load(filename="data.json")
    if File.exist?(filename)
      file = File.read(filename)
      h = JSON.parse(file)

      apply(h)
    end
  end

  def apply(h)
    @bot.point = Point.new(h["point"])
    @bot.waypoints = h["waypoints"].collect { |x| Point.new(x) } || []
  end

  def save(filename=DATAFILE)
    data = {
      "point" => @bot.point.to_h,
      "waypoints" => @bot.waypoints.collect(&:to_h)
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

    puts output
    
    f = File.open(LOGFILE, "a")
    f.puts output
    f.close
  end
  
end
