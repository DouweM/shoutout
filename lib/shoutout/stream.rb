module Shoutout
  class Stream
    include QuickAccess

    attr_reader :url

    class << self
      def open(url)
        stream = new(url)

        begin
          stream.connect
          yield stream
        ensure
          stream.disconnect
        end
      end

      def metadata(url)
        new(url).metadata
      end
    end

    def initialize(url, timeout = 5)
      @url = url
      @timeout = timeout
      @socket = nil
    end

    def connected?
      @connected
    end

    def connect
      return false if @connected

      uri = URI.parse(@url)
      path = uri.path
      if path == nil || path == ""
        path = "/"
      end
      getSocket
      @socket.puts send_header_request(path, uri.host)

      # Read status line
      status_line = @socket.gets
      status_code = status_line.match(/\A(HTTP\/[0-9]\.[0-9]|ICY) ([0-9]{3})/)[2].to_i

      @connected = true

      read_headers

      if status_code >= 300 && status_code < 400 && headers[:location]
        disconnect

        @url = URI.join(uri, headers[:location]).to_s

        return connect
      end

      unless status_code >= 200 && status_code < 300
        disconnect

        return false
      end

      unless metadata_interval
        disconnect

        return false
      end

      @read_metadata_thread = Thread.new(&method(:read_metadata))

      true
    end

    def send_header_request(address, host)
      return "GET #{address} HTTP/1.1\r\nIcy-Metadata: 1\r\nHost: #{host}\r\nUser-Agent: iTunes/9.1.1\r\nAccept: */*\r\n\r\n";
    end

    def disconnect
      return false unless @connected

      @connected = false

      @socket.close if @socket && !@socket.closed?
      @socket = nil
      if @read_metadata_thread != nil
        Thread.kill(@read_metadata_thread)
      end
      if @last_metadata_change_thread != nil
        Thread.kill(@last_metadata_change_thread)
      end
      true
    end

    def listen
      return unless @connected

      @read_metadata_thread.join
      @last_metadata_change_thread.join if @last_metadata_change_thread
    end

    def metadata
      return @metadata if defined?(@metadata)

      original_metadata_change_block = @metadata_change_block

      received = false
      metadata_change do |new_metadata|
        received = true
      end

      already_connected = @connected
      connect unless already_connected

      sleep 0.015 until received

      disconnect unless already_connected

      metadata_change(&original_metadata_change_block) if original_metadata_change_block

      @metadata
    end

    def metadata_change(&block)
      @metadata_change_block = block

      report_metadata_change(@metadata) if defined?(@metadata)

      true
    end

    def getSocket
       uri = URI.parse(@url)
       # Convert the passed host into structures the non-blocking calls
       # can deal with
       addr = Socket.getaddrinfo(uri.host, nil)
       sockaddr = Socket.pack_sockaddr_in(uri.port, addr[0][3])

       @socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0).tap do |socket|
         socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

         begin
           # Initiate the socket connection in the background. If it doesn't fail
           # immediatelyit will raise an IO::WaitWritable (Errno::EINPROGRESS)
           # indicating the connection is in progress.
           socket.connect_nonblock(sockaddr)

         rescue IO::WaitWritable
           # IO.select will block until the socket is writable or the timeout
           # is exceeded - whichever comes first.
           if IO.select(nil, [socket], nil, @timeout)
             begin
               # Verify there is now a good connection
               socket.connect_nonblock(sockaddr)
             rescue Errno::EISCONN
               # Good news everybody, the socket is connected!
             rescue
               # An unexpected exception was raised - the connection is no good.
               socket.close
               raise
             end
           else
             # IO.select returns nil when the socket is not ready before timeout
             # seconds have elapsed
             socket.close
             raise "Connection timeout"
           end
         end
       end
    end

    private
      def read_headers
        raw_headers = ""
        while line = @socket.gets
          break if line.chomp == ""
          raw_headers << line
        end
        @headers = Headers.parse(raw_headers)
      end

      def read_metadata
        while @connected
          # Skip audio data
          data = @socket.read(metadata_interval + 255) || raise(EOFError)
          raw_data = data.unpack("A*")[0]
          match = raw_data.match(/(StreamTitle.*;)/)
          next if match.nil?

          @metadata = Metadata.parse(match[1])

          report_metadata_change(@metadata)
        end
      rescue Errno::EBADF, IOError => e
        # Connection lost
        disconnect
      end

      def report_metadata_change(metadata)
        @last_metadata_change_thread = Thread.new(metadata, @last_metadata_change_thread) do |metadata, last_metadata_change_thread|
          last_metadata_change_thread.join if last_metadata_change_thread

          @metadata_change_block.call(metadata) if @metadata_change_block
        end
      end

      def headers
        return @headers if defined?(@headers)

        # Connected but no headers? I give up.
        return [] if @connected

        connect && disconnect

        @headers
      end
  end
end
