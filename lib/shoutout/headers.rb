module Shoutout
  class Headers < Hash
    def self.parse(raw_headers)
      headers = {}
      raw_headers.split("\r\n").each do |line|
        key, value = line.chomp.split(":", 2)
        if key != nil && value != nil
            headers[key.strip] = value.strip
        end
      end

      new(headers)
    end

    def initialize(constructor = {})
      if constructor.is_a?(Hash)
        super()
        update(constructor)
      else
        super(constructor)
      end
    end

    alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
    alias_method :regular_update, :update unless method_defined?(:regular_update)

    def update(other_hash)
      if other_hash.is_a?(Headers)
        super(other_hash)
      else
        other_hash.each_pair do |key, value|
          if block_given? && has_key?(key)
            value = yield(convert_key(key), self[key], value)
          end
          self[key] = value
        end
        self
      end
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      regular_writer(convert_key(key), value)
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

    private
      def convert_key(key)
        (key.kind_of?(Symbol) ? key.to_s.gsub(/_/, "-") : key).downcase
      end
  end
end