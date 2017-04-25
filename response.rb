require './street_view_checker.rb'

class Response < JSONStruct
  # url
  # text
  # success
  # point
  
  #
  # check the current street map view to see if there's imagery or not
  #
  def valid?
    return false if self.valid == false || !self.point || !self.point.url
    point.valid?
  end

  def image
    return nil if ! valid?
    point.image_path
  end
end
