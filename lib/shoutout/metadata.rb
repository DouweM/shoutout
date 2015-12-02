module Shoutout
  class Metadata < Hash
    def self.parse(raw_metadata)
      metadata = {}
      raw_metadata.split(";").each do |key_value_pair|
        key, value = key_value_pair.split("=", 2)
        if !key.nil? && !value.nil? &&
          valuetaken = value.match(/\A'(.*)'\z/)
          if !valuetaken.nil?
            valuetakens = valuetaken[1].ensure_encoding('UTF-8',
                                                        :external_encoding  => :sniff,
                                                        :invalid_characters => :drop
                            )
            metadata[key] = valuetakens.scrub!
          end
        end
      end

      new(metadata)
    end

    def initialize(constructor = {})
      if constructor.is_a?(Hash)
        super()
        update(constructor)
      else
        super(constructor)
      end
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      super(convert_key(key), value)
    end

    alias_method :store, :[]=

    def key?(key)
      super(convert_key(key))
    end

    alias_method :include?, :key?
    alias_method :has_key?, :key?
    alias_method :member?, :key?

    def delete(key)
      super(convert_key(key))
    end

    module QuickAccess
      def website
        self[:stream_url]
      end

      def now_playing
        self[:stream_title]
      end

      def artist
        artist_and_song[0]
      end

      def song
        artist_and_song[1]
      end

      private
        def artist_and_song
          @artist_and_song ||= now_playing.split(" - ", 2)
        end
    end

    include QuickAccess

    private
      def convert_key(key)
        key.kind_of?(Symbol) ? Util.camelize(key.to_s) : key
      end
  end
end
