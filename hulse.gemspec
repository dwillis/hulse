# coding: utf-8
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hulse/version'

Gem::Specification.new do |spec|
  spec.name          = "hulse"
  spec.version       = Hulse::VERSION
  spec.authors       = ["Derek Willis"]
  spec.email         = ["dwillis@gmail.com"]
  spec.summary       = %q{Hulse is a Ruby gem for accessing House and Senate roll call votes and member data from the official sources on house.gov and senate.gov}
  spec.description   = %q{Turns House and Senate votes and members into Ruby objects for your legislative pleasure.}
  spec.homepage      = ""
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 3.3.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_dependency "httparty"
  spec.add_dependency "nokogiri"
  spec.add_dependency "oj"
  spec.add_dependency "american_date"
  spec.add_dependency "activesupport"
  spec.add_dependency "memoist"
  spec.add_dependency "rest-client"
  spec.add_dependency "htmlentities"
end
