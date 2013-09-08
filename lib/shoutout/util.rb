module Shoutout
  module Util
    def self.camelize(term)
      term = term.sub(/^[a-z\d]*/) { $&.capitalize }
      term.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
    end
  end
end