require 'spec_helper'

describe RasperClient do
  before :all do
    @port = 7888
    @client = RasperClient::Client.new(host: 'localhost', port: @port)
    @server = RasperClient::FakeServer.new.start(@port)
  end

  context 'when cannot connect to server' do
    it 'throws an error' do
      client = RasperClient::Client.new(host: 'localhost', port: 9876)
      expect { client.add(any: 'thing') }.to raise_error(
        RasperClient::ConnectionRefusedError)
    end
  end
end