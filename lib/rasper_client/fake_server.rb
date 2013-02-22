require 'sinatra/base'

module RasperClient
  class FakeServer
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
      { success: true }.to_json
    end

    post '/generate' do
      { content: "some content" }.to_json
    end
  end
end