# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gitm/version'

Gem::Specification.new do |spec|
  spec.name          = 'gitm'
  spec.version       = Gitm::VERSION
  spec.authors       = ['Mayfly']
  spec.email         = ['mayfly277@gmail.com']
  spec.description   = %q{Gitm is a command line tool utility for manage git repository}
  spec.summary       = %q{Gitm : welcome to easy branch view and bug tracking link}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'highline', '>= 1.7'
  spec.add_dependency 'rugged', '>=0.23'
  spec.add_dependency 'ruby-progressbar', '>=1.7'
  #spec.add_dependency 'slop', '~>3.0'
  spec.add_dependency 'colorize'
  spec.add_dependency 'activeresource'
  spec.add_dependency 'terminal-table'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
