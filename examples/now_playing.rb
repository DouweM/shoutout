#!/usr/bin/env ruby

# This script listens to the specified audio stream and lets you know through
# Terminal and OS X's Notification Center when the song changes.

require "shoutout"
require "terminal-notifier"
require "active_support/all"

unless ARGV[0]
  STDERR.puts "Usage: now_playing.rb [STREAM URL]"
  exit 1
end

shoutout = Shoutout.new(ARGV[0])

shoutout.connect

puts "Listening to #{shoutout.name}"

shoutout.metadata_change do |metadata|
  now_playing = [metadata.artist.titleize, metadata.song.titleize].join(" - ")

  puts "Now playing: #{now_playing}"

  TerminalNotifier.notify(now_playing,  title:    shoutout.name,
                                        sender:   "com.apple.iTunes",
                                        activate: "com.apple.iTunes",
                                        group:    Process.pid)
end

trap("INT") { shoutout.disconnect }
shoutout.listen