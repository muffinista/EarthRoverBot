require './json_struct.rb'
class Request < JSONStruct
  # text
  # privileged?
  # created_at
  def initialize(args)
    super(args)
    self.created_at ||= Time.now
  end
  
  def tokens
    @_tokens ||= text.downcase.split
  end
end
