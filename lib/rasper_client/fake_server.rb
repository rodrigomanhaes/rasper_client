require 'sinatra/base'
require 'json'
require 'base64'

module RasperClient
  class FakeServer
    class << self
      attr_accessor :last_added_report
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
      { content: "some content" }.to_json
    end
  end
end