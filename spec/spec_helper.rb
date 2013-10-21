require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'rasper_client'))

require 'pry-rails'

def resource(arquivo)
  File.expand_path(File.join(File.dirname(__FILE__), 'resources', arquivo))
end