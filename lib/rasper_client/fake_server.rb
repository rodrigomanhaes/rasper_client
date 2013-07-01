require 'sinatra/base'
require 'json'
require 'base64'

Rack::Utils.key_space_limit = 262144

module RasperClient
  class FakeServer
    class << self
      attr_accessor :last_added_report, :last_generated_report
    end

    def start(port)
      @thread = Thread.new { FakeApp.run! :port => port }
      sleep 1
      self
    end

    def stop
      @thread.kill
      self
    end
  end

  class FakeApp < Sinatra::Application
    post '/add' do
      content_type :json
      FakeServer.last_added_report = JSON.parse(request.body.read)
      { success: true }.to_json
    end

    post '/generate' do
      content_type :json
      FakeServer.last_generated_report = JSON.parse(request.body.read)
      { content: Base64.encode64(File.read(resource('dummy.pdf'))) }.to_json
    end
  end
end