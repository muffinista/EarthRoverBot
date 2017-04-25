require 'open-uri'
require 'tempfile'

class StreetViewChecker
  # this is the color of the 'no imagery available' tile
  NO_IMAGERY_COLOR = 'E4E3DF'

  def valid_street_map?(tmpurl)
    #STDERR.puts tmpurl
    
    begin
      dest = Tempfile.new('pic')
      dest << open(tmpurl).read
      dest.close
      
      # crop down to one corner and get the color of the image
      color = `convert #{dest.path} -crop 40x40+0+0  -resize 1x1 txt:`

      return (color !~ /#{NO_IMAGERY_COLOR}/)
    rescue OpenURI::HTTPError
      false
    ensure
      dest && dest.close
      dest && dest.unlink
    end

    false
  end


  def valid_location?(lat, lon)
    tmpurl = url(lat, lon)
    return valid_street_map?(tmpurl)
  end
end
