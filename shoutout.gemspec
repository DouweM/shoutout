$:.push File.expand_path("../lib", __FILE__)
require "shoutout/version"

Gem::Specification.new do |s|
  s.name          = "shoutout"
  s.version       = Shoutout::VERSION

  s.platform      = Gem::Platform::RUBY
  s.author        = "Douwe Maan"
  s.email         = "douwe@selenight.nl"
  s.homepage      = "https://github.com/DouweM/shoutout"
  s.description   = "A Ruby library for easily getting metadata from Shoutcast-compatible audio streaming servers"
  s.summary       = "Read metadata from Shoutcast streams"
  s.license       = "MIT"

  s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.md Rakefile Gemfile)
  s.test_files    = Dir.glob("spec/**/*")
  s.require_path  = "lib"
  s.add_dependency("tcp_timeout")
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end