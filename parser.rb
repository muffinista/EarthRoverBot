#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'sequel'

class Parser
  COMMANDS = ["help", "status", "move",
              "turn", "left", "right", "face",
              "map", "auto", "repoint", "waypoint"].freeze

  PRIVILEGED_COMMANDS = (
    COMMANDS +
    ["reset", "target", "targets"]
  ).freeze

  def initialize(bot:nil, manager:nil)
    @bot = bot
    @manager = manager
  end
  
  def handle(request)
    tokens = request.tokens

    puts tokens.inspect
    return if tokens.empty?

    result = Response.new(
      url:nil,
      text: "sorry, that command doesn't make any sense to me. my instructions are here http://muffinlabs.com/rover/"
    )
    handled = false

    commands = request.privileged? ? PRIVILEGED_COMMANDS : COMMANDS
    
    while !tokens.empty? && !handled
      cmd = tokens.shift.downcase.gsub(/[^a-z]/, "").strip
      if commands.include?(cmd)
        handled = true
        result = @bot.send cmd.to_sym, tokens

        update(request, result)
      end
    end

    result
  end

  def help(opts={})
    {text: "Hi! You can get a list of commands here: http://muffinlabs.com/earth-rover-bot.html"}
  end

  def update(request, result)
    return unless @manager
    @manager.update_log(request, result)
  end
end

