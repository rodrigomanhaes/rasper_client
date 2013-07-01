require 'spec_helper'

describe RasperClient do
  before :all do
    @port = 7888
    @client = RasperClient::Client.new(host: 'localhost', port: @port)
    @server = RasperClient::FakeServer.new.start(@port)
  end

  let(:jrxml_content) { File.read(resource('programmers.jrxml')) }
  let(:image_content) { File.read(resource('imagem.jpg')) }

  it 'adds a report' do
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
    image['content'].should == Base64.encode64(image_content)
  end

  it 'adds only an image' do
    params = {
      images: [
        {
          name: 'imagem.jpg',
          content: image_content
        }
      ]
    }
    @client.add(params).should == true
    last = RasperClient::FakeServer.last_added_report
    last['name'].should be_nil
    last['content'].should be_nil
    last['images'].should have(1).image
    image = last['images'][0]
    image['name'].should == 'imagem.jpg'
    image['content'].should == Base64.encode64(image_content)
  end

  it 'generates report' do
    pdf_content = @client.generate(
      name: 'programmers',
      data: [
        { name: 'Linus', software: 'Linux' },
        { name: 'Yukihiro', software: 'Ruby' },
        { name: 'Guido', software: 'Python' }
      ],
      parameters: {
        'CITY' => 'Campos dos Goytacazes, Rio de Janeiro, Brazil',
        'DATE' => '02/01/2013'
      }
    )

    Base64.encode64(pdf_content).should == \
      Base64.encode64(File.read(resource('dummy.pdf')))
    RasperClient::FakeServer.last_generated_report.should == {
      'name' => 'programmers',
      'data' => [
        { 'name' => 'Linus', 'software' => 'Linux' },
        { 'name' => 'Yukihiro', 'software' => 'Ruby' },
        { 'name' => 'Guido', 'software' => 'Python' }
      ],
      'parameters' => {
        'CITY' => 'Campos dos Goytacazes, Rio de Janeiro, Brazil',
        'DATE' => '02/01/2013'
      }
    }

  end

  context 'when cannot connect to server' do
    it 'throws an error' do
      client = RasperClient::Client.new(host: 'localhost', port: 9876)
      expect { client.add(content: 'thing') }.to raise_error(
        RasperClient::ConnectionRefusedError)
    end
  end
end