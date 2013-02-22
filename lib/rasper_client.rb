require "rasper_client/version"

module RasperClient
  autoload :Client, 'rasper_client/client'
  autoload :FakeServer, 'rasper_client/fake_server'
  autoload :ConnectionRefusedError, 'rasper_client/errors'
end