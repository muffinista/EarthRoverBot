require 'ostruct'
require 'json'
require 'pry'

class JSONStruct < OpenStruct
  def to_json(*args)
    to_h.to_json(args)
  end
end
