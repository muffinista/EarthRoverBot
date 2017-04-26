#!/usr/bin/env ruby

require 'rubygems'
require 'dotenv/load'
require 'chatterbot/dsl'

require './request.rb'
require './response.rb'
require './point.rb'
require './rover.rb'
require './parser.rb'
require './manager.rb'


ADMIN_USERS = ["muffinista"]
BOT_NAME = "@#{client.user.screen_name}".freeze
TIME_BETWEEN_MOVES = 60*20 # auto-move every 20 minutes


$mutex = Mutex.new
$last_tweet_at = Time.now.to_i
@sleep_rate = 20

@manager = Manager.new
@parser = Parser.new(rover:@manager.rover, manager:@manager)

Thread.abort_on_exception = true

def unfollow_unfollowers
  follower_ids = client.follower_ids.to_a
  following = client.friend_ids.to_a

  diff = following - follower_ids
  puts diff.inspect
  puts diff.count
  client.unfollow(diff)

  follower_ids = client.follower_ids.to_a
  following = client.friend_ids.to_a

  diff = follower_ids - following
  puts diff.inspect
  puts diff.count
  diff.each { |id|
    client.follow(id) rescue nil
  }
end

def tweet_result(result, tweet=nil)
  postfix = if result.point && result.point.current_waypoint
              result.point.current_waypoint
            else
              Random.new.rand(10..99)
            end

  txt = if tweet
          "#{tweet_user(tweet)} #{result.text}".strip
        else
          result.text.strip
        end

  txt = "#{txt} (#{postfix})"
  
  STDERR.puts "tweeting #{txt}"

  opts = {}
  if result.lat
    opts[:lat] = result.lat
    opts[:long] = result.lon
    opts[:display_coordinates] = true
  end
  
  if tweet
    opts[:in_reply_to_status_id] = tweet.id
  end

  image_path = result.image
  if image_path
    client.update_with_media txt, File.open(image_path), opts
  else
    if tweet
      reply txt, tweet
    else
      tweet txt
    end
  end
end


use_streaming

followed do |user|
  follow user
end

direct_messages do |tweet|
  $mutex.synchronize {
    STDERR.puts tweet.inspect
    next if ! ADMIN_USERS.include? tweet.sender.screen_name
    
    cmd = tweet.text.gsub(/@EarthRoverBot/i, "")
    STDERR.puts cmd
    
    req = Request.new(privileged?:ADMIN_USERS.include?(tweet.sender.screen_name), text:cmd)
    result = @parser.handle(req)
    @manager.save
    
    STDERR.puts result.inspect
    
    client.create_direct_message tweet.sender, result.text
  }
end

home_timeline do |tweet|
  $mutex.synchronize {
    next if tweet.text !~ /^#{BOT_NAME}/i
    
    cmd = tweet.text.gsub(/#{BOT_NAME}/i, "")
    STDERR.puts cmd
    
    req = Request.new(privileged?:ADMIN_USERS.include?(tweet.user.screen_name), text:cmd)
    result = @parser.handle(req)
    @manager.save

    STDERR.puts result.inspect
    
    $last_tweet_at = Time.now.to_i
    tweet_result(result, tweet)
  }
end

timer_thread = Thread.new {
  while(true) do
    begin     
      if Time.now.to_i - $last_tweet_at > TIME_BETWEEN_MOVES
        $mutex.synchronize {
          $last_tweet_at = Time.now.to_i

          req = Request.new(text:"auto")
          result = @parser.handle(req)
          @manager.save

          if !result.valid? || result.text =~ /Sorry/ || result[:text] =~ /move there/
          else
            tweet_result(result)
          end
        }
      end
      sleep @sleep_rate
    rescue StandardError => e
      STDERR.puts "timer thread exception #{e.inspect}"
      raise e
    end
  end
}


timer_thread.run
