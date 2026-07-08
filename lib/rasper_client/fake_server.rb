require 'sinatra/base'
require 'json'
require 'base64'

Rack::Utils.key_space_limit = 262144 if Rack::Utils.respond_to?(:key_space_limit=)

module RasperClient
  class FakeServer
    class << self
      attr_accessor :last_added_report, :last_generated_report, :last_generate_pdfa
    end

    def start(port, username, password)
      @thread = Thread.new do
        FakeAppCreator
          .create(username: username, password: password)
          .run!(port: port, quiet: true)
      end
      sleep 1
      self
    end

    def stop
      @thread.kill
      self
    end
  end

  class FakeAppCreator < Sinatra::Application
    def self.create(username: nil, password: nil)
      Class.new(Sinatra::Application) do
        use Rack::Auth::Basic, "Protected Area" do |user, pass|
          username == user && password == pass
        end if username && password

        post '/add' do
          content_type :json
          request.body.rewind
          FakeServer.last_added_report = JSON.parse(request.body.read)
          { success: true }.to_json
        end

        post '/generate' do
          content_type :json
          request.body.rewind
          body = JSON.parse(request.body.read)
          FakeServer.last_generate_pdfa = body['pdfa']
          FakeServer.last_generated_report = JSON.parse(Base64.decode64(body['data']))
          { content: Base64.encode64(File.read(resource('dummy.pdf'))) }.to_json
        end
      end
    end
  end
end
