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

stream = Shoutout::Stream.new(ARGV[0])

stream.connect

puts "Listening to #{stream.name}"

stream.metadata_change do |metadata|
  now_playing = [metadata.artist.titleize, metadata.song.titleize].join(" - ")

  puts "Now playing: #{now_playing}"

  TerminalNotifier.notify(now_playing,  title:    stream.name,
                                        sender:   "com.apple.iTunes",
                                        activate: "com.apple.iTunes",
                                        group:    Process.pid)
end

trap("INT") { stream.disconnect }
stream.listen