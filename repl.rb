require './request.rb'
require './response.rb'
require './point.rb'
require './rover.rb'
require './parser.rb'
require './manager.rb'

require 'pry'

class REPL
  def initialize(m, p)
    @manager = m
    @parser = p
    @status = nil
  end

  def run
    repl = -> prompt do
      print prompt
      x = STDIN.gets
      if x
        req = Request.new(privileged?:true, text:x.chomp!)
        @status = @parser.handle(req)
        @manager.save
      end
    end

    loop do
      if @status
        puts @status
        puts @status.valid?
      end

      repl[">> "]
    end
  end
end


if __FILE__ == $0
  m = Manager.new
  
  parser = Parser.new(rover:m.rover, manager:m)
  r = REPL.new(m, parser)
  r.run
end
