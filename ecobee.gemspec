# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecobee/version'

Gem::Specification.new do |spec|
  spec.name          = "ecobee"
  spec.version       = Ecobee::VERSION
  spec.authors       = ["Rob Zwissler"]
  spec.email         = ["rob@zwissler.org"]

  spec.summary       = %q{Ecobee API - token registration, persistent HTTP GET/PUSH }
  spec.description   = %q{Implements Ecobee API with PIN-based token registration & renewal, persistent HTTP connections }
  spec.homepage      = "https://github.com/robzr/ecobee"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 3.2'

  spec.add_development_dependency "bundler", ">= 2.2"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_runtime_dependency('addressable', ">= 2.8.4")
end
