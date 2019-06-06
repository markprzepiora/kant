# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kant/version'

Gem::Specification.new do |spec|
  spec.name          = "kant"
  spec.version       = Kant::VERSION
  spec.authors       = ["Mark Przepiora"]
  spec.email         = ["mark.przepiora@gmail.com"]
  spec.summary       = %q{A tiny, non-magical authorization library}
  spec.description   = %q{Kant is a tiny authorization library for your Ruby (especially Rails and/or ActiveRecord) projects.}
  spec.homepage      = "https://github.com/markprzepiora/kant"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency "with_model", "~> 1.2.1"
  spec.add_development_dependency "sqlite3", "~> 1.3.10"
  spec.add_development_dependency "activerecord", ">= 3.2"
end
