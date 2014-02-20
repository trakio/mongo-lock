Gem::Specification.new do |spec|
  spec.name        = "mongo-lock"
  spec.version  = Trakio::VERSION
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

end
