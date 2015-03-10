$:.unshift File.expand_path('../lib', __FILE__)
require 'es6-module-mapper/version'

Gem::Specification.new do |s|
  s.name = 'es6-module-mapper'
  s.version = ES6ModuleMapper::VERSION
  s.summary = 'Adds support for ES6 modules to Sprockets'
  s.description = s.summary
  s.license = 'BSD'

  s.files = Dir['README.md', 'LICENSE', 'lib/**/*.rb', 'lib/**/*.js']

  s.add_dependency 'sprockets', '~> 3.0.0.beta'
  s.add_dependency 'yajl-ruby', '~> 1.2'

  s.required_ruby_version = '>= 2.0.0'

  s.authors = ['Jesse Stuart']
  s.email = ['jesse@jessestuart.ca']
  s.homepage = 'https://github.com/jvatic/es6-module-mapper'
end
