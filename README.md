# shoutout [![Build Status](https://travis-ci.org/DouweM/shoutout.png?branch=master)](https://travis-ci.org/DouweM/shoutout)

A Ruby library for easily getting metadata from Shoutcast-compatible audio streaming servers.

## Installation

```sh
gem install shoutout
```

Or in your Gemfile:

```ruby
gem "shoutout"
```

## Usage

```ruby
require "shoutout"

shoutout = Shoutout.new("http://82.201.100.5:8000/radio538")

# Explicitly open a connection with the server. You're responsible for closing this connection using `#disconnect`.
shoutout.connect

# If you call any of the reader methods below without having explicitly opened a connection, 
# one will be opened and closed around reading the information implicitly.
# This is convenient if you're only looking for one piece of information, but it is of course 
# very inefficient if you're going to do multiple reads.

# Stream info
shoutout.name         # => "RADIO538" 
shoutout.description  # => "ARE YOU IN"
shoutout.genre        # => "Various"
shoutout.notice       # => nil in this case, but this could very well have a value for your stream
shoutout.content_type # => "audio/mpeg"
shoutout.bitrate      # => 128
shoutout.public?      # => true
shoutout.audio_info   # => { :samplerate => 44100, :bitrate => 128, :channels => 2 }

# Current metadata
shoutout.metadata # => { "StreamTitle" => "ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE", "StreamUrl" => "http://www.radio538.nl" }

# The Metadata object is a Hash that has been extended with the following features:
shoutout.metadata[:stream_title]  # => "ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE"
shoutout.metadata[:stream_url]    # => "http://www.radio538.nl"
shoutout.metadata.now_playing     # => "ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE"
shoutout.metadata.website         # => "http://www.radio538.nl"
shoutout.metadata.artist          # => "ARMIN VAN BUUREN"
shoutout.metadata.song            # => "THIS IS WHAT IT FEELS LIKE"

# Conveniently, `#now_playing` and `#website` are also available on the Shoutout instance:
shoutout.now_playing  # => "ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE"
shoutout.website      # => "http://www.radio538.nl"

# For convenience, all of the reader methods above are also available as class methods:
Shoutout.now_playing("http://82.201.100.5:8000/radio538") # => "ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE"
# Just like the equivalent `Shoutout.new("http://82.201.100.5:8000/radio538").now_playing`,
# this will automatically open and close a connection around reading the information.

# You can have a block called every time the metadata changes:
shoutout.metadata_change do |metadata|
  puts "Now playing: #{metadata.song} by #{metadata.artist}"
end
# Of course, this only works with an explicitly opened connection.

# If you're done setting up but want the program to keep listening for metadata, say so:
shoutout.listen
# Note that listening will only end when the connection is lost or the end of file is reached, 
# so anything that comes after this call will only then be executed. 
# This will generally be the last call in your program.

# If we don't want to wait around and listen, just let the program exit or disconnect explicitly:
shoutout.disconnect
```

## Examples
Check out the [`examples/`](examples) folder for an example that I actually use myself.

## License
Copyright (c) 2013 Douwe Maan

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.