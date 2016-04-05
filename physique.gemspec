# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'physique/version'

Gem::Specification.new do |spec|
  spec.name          = 'physique'
  spec.version       = Physique::VERSION
  spec.authors       = ['Robert Scaduto']
  spec.email         = ['rscaduto@thirdwave.it']
  spec.description   = %q{Beautiful builds for .NET projects}
  spec.summary       = %q{A conventional build framework supporting NUnit, FluentMigrator and Octopus Deploy}
  spec.homepage      = 'http://github.com/scardetto/physique'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec', '2.14.1'
  spec.add_development_dependency 'guard-rspec', '~> 4.3.1'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_dependency 'activesupport', '~> 4.1'
  spec.add_dependency 'albacore', '~> 2.5'
  spec.add_dependency 'map', '~> 6.5'
  spec.add_dependency 'rake', '~> 10'
  spec.add_dependency 'semver2', '~> 3.4'
end
