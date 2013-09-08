class Shoutout
  module QuickAccess
    def self.included(base)
      base.extend(ClassMethods)
    end

    def content_type
      headers[:content_type]
    end

    def audio_info
      return @audio_info if defined?(@audio_info)

      raw_audio_info = headers[:ice_audio_info]
      return @audio_info = nil if raw_audio_info.nil?

      audio_info = {}

      raw_audio_info.split(";").each do |key_value_pair|
        key, value = key_value_pair.split("=")
        key = key.sub(/\Aice-/, "").to_sym
        value = value.to_i

        audio_info[key] = value
      end

      @audio_info = audio_info
    end

    %w(name description genre notice).each do |method|
      define_method(method) do
        headers["icy-#{method}"]
      end
    end

    def bitrate
      headers[:icy_br].to_i
    end

    def public?
      headers[:icy_pub] == "1"
    end

    def metadata_interval
      headers[:icy_metaint].to_i if headers[:icy_metaint]
    end

    def now_playing
      metadata.now_playing
    end

    def website
      metadata.website || headers[:icy_url]
    end

    module ClassMethods
      QuickAccess.instance_methods.each do |method|
        define_method(method) do |url|
          new(url).send(method)
        end
      end
    end
  end
end