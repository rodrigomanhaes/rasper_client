require 'spec_helper'

describe RasperClient do
  before :all do
    @port = 7888
    @client = RasperClient::Client.new(host: 'localhost', port: @port)
    @server = RasperClient::FakeServer.new.start(@port)
  end

  it 'adds a report' do
    jrxml_content = File.read(resource('programmers.jrxml'))
    image_content = File.read(resource('imagem.jpg'))
    params = {
      name: 'programmers',
      content: jrxml_content,
      images: [
        {
          name: 'imagem.jpg',
          content: image_content
        }
      ]}
    @client.add(params).should == true
    last = RasperClient::FakeServer.last_added_report
    last['name'].should == 'programmers'
    last['content'].should == Base64.encode64(jrxml_content)
    last['images'].should have(1).image
    image = last['images'][0]
    image['name'].should == 'imagem.jpg'
    image['content'].should == \
      Base64.encode64(image_content)
  end

  context 'when cannot connect to server' do
    it 'throws an error' do
      client = RasperClient::Client.new(host: 'localhost', port: 9876)
      expect { client.add(content: 'thing') }.to raise_error(
        RasperClient::ConnectionRefusedError)
    end
  end
end