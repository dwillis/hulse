# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hulse/version'

Gem::Specification.new do |spec|
  spec.name          = "hulse"
  spec.version       = Hulse::VERSION
  spec.authors       = ["Derek Willis"]
  spec.email         = ["dwillis@gmail.com"]
  spec.summary       = %q{Hulse is a Ruby gem for accessing House and Senate roll call votes from the official sources on house.gov and senate.gov}
  spec.description   = %q{Turns House and Senate votes into Ruby objects for your legislative pleasure.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_dependency "httparty"
  spec.add_dependency "oj"
end
