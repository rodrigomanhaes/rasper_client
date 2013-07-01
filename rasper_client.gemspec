# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rasper_client/version'

Gem::Specification.new do |gem|
  gem.name          = "rasper_client"
  gem.date          = %q{2013-07-01}
  gem.version       = RasperClient::VERSION
  gem.authors       = ["Rodrigo Manhães"]
  gem.email         = ["rmanhaes@gmail.com"]
  gem.description   = 'Ruby client to RasperServer.'
  gem.summary       = "JRuby client to RasperServer."
  gem.homepage      = "https://github.com/rodrigomanhaes/rasper_client"
  gem.licenses      = ['MIT']

  gem.files         = Dir.glob('lib/**/*.rb') +
                      %w(README.rst LICENSE.txt Rakefile Gemfile)
  gem.require_paths = ["lib"]

  gem.add_dependency 'rake'
  gem.add_dependency 'activesupport'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sinatra'
end