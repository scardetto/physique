# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cruxrake/version'

Gem::Specification.new do |spec|
  spec.name          = 'cruxrake'
  spec.version       = CruxRake::VERSION
  spec.authors       = ['Robert Scaduto']
  spec.email         = ['rscaduto@core4tek.com']
  spec.description   = %q{Rake tasks for Crux applications}
  spec.summary       = %q{Built in support for  }
  spec.homepage      = 'http://github.com/core4tek/cruxrake'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec', '2.14.1'
  spec.add_dependency 'activesupport', '~> 4.1'
  spec.add_dependency 'map', '~> 6.5'
  spec.add_dependency 'albacore', '2.0.0.rc.12'
end