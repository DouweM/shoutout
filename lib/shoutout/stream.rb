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

    def initialize(url)
      @url = url
    end

    def connected?
      @connected
    end

    def connect
      return false if @connected
      uri = URI.parse(@url)

      @socket = TCPTimeout::TCPSocket.new(uri.host, uri.port, connect_timeout: 10, write_timeout: 9)
      @socket.write(send_header_request(uri.path, uri.host))

      # Read status line
      status_line = @socket.read(20)
      print status_line
      if status_line != nil
        status_code = status_line.match(/\A(HTTP\/[0-9]\.[0-9]|ICY) ([0-9]{3})/)
        if status_code != nil
          status_code = status_code[2].to_i
        else status_code = false
        end
      else
        status_code = false
      end


      @connected = true

      read_headers

      if status_code != false && status_code >= 300 && status_code < 400 && headers[:location]
        disconnect
        
        if @url_retry != nil
          raise(SocketError) if @url == @url_retry
        end
        @url = headers[:location].to_s
        @url_retry = headers[:location].to_s

        return connect
      end
      
      if status_code != false
          unless status_code >= 200 && status_code < 300
            disconnect
    
            return false
          end
      end


      unless metadata_interval
        disconnect

        return false
      end

      @read_metadata_thread = Thread.new(&method(:read_metadata))

      true
    end

    def disconnect
      return false unless @connected

      @connected = false

      @socket.close if @socket && !@socket.closed?
      @socket = nil

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

    def send_header_request(address, host)
        return "GET #{address} HTTP/1.1\r\nAccept-Encoding: identity\r\nIcy-Metadata: 1\r\nHost: #{host}\r\nConnection: close\r\nUser-Agent: iTunes/9.1.1\r\n\r\n";
    end

    private
      def read_headers
        raw_headers = ""
        lines = @socket.read(1624)
        print "lines: " + lines
        lines = lines.split("\r\n")
        lines.each do |line|
          break if line == "\r\n" || line == ""
          raw_headers << line
        end
        print "headers: " + raw_headers
        @headers = Headers.parse(raw_headers)
      end

      def read_metadata
        while @connected
          # Skip audio data
          data = @socket.read(metadata_interval) || raise(EOFError)

          data = @socket.read(1) || raise(EOFError)
          metadata_length = data.unpack("c")[0] * 16
          next if metadata_length == 0

          data = @socket.read(metadata_length) || raise(EOFError)
          raw_metadata = data.unpack("A*")[0]
          @metadata = Metadata.parse(raw_metadata)
          
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