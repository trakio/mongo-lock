# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongo-lock/version'

Gem::Specification.new do |spec|
  spec.name        = "mongo-lock"
  spec.version     = Mongo::Lock::VERSION
  spec.authors     = ["Matthew Spence"]
  spec.email       = "msaspence@gmail.com"
  spec.homepage    = "https://github.com/trakio/mongo-lock"
  spec.summary     = "Pessimistic locking for Ruby and MongoDB"
  spec.description = "Key based pessimistic locking for Ruby and MongoDB. Is this key avaliable? Yes - Lock it for me for a sec will you. No - OK I'll just wait here until its ready."
  spec.required_rubygems_version = ">= 1.3.6"
  spec.license = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # s.add_dependency 'some-gem'
  spec.extra_rdoc_files = ['README.md', 'LICENSE']

  spec.add_development_dependency 'mongo'
  spec.add_development_dependency 'moped'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'bson_ext'
  spec.add_development_dependency 'rails', '~> 4.0.0'

end
