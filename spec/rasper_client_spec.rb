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
      ]
    }
    expect(@client.add(params)).to be true
    last = RasperClient::FakeServer.last_added_report
    expect(last['name']).to eq 'programmers'
    expect(last['content']).to eq Base64.encode64(jrxml_content)
    expect(last['images'].size).to eq 1
    image = last['images'][0]
    expect(image['name']).to eq 'imagem.jpg'
    expect(image['content']).to eq Base64.encode64(image_content)
  end

  it 'adds only one image' do
    params = {
      images: [
        {
          name: 'imagem.jpg',
          content: image_content
        }
      ]
    }
    expect(@client.add(params)).to be true
    last = RasperClient::FakeServer.last_added_report
    expect(last['name']).to be_nil
    expect(last['content']).to be_nil
    expect(last['images'].size).to eq 1
    image = last['images'][0]
    expect(image['name']).to eq 'imagem.jpg'
    expect(image['content']).to eq Base64.encode64(image_content)
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

    expect(Base64.encode64(pdf_content)).to eq \
      Base64.encode64(File.read(resource('dummy.pdf')))
    expect(RasperClient::FakeServer.last_generated_report).to eq \
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
  end

  context 'timeout' do
    it 'allows pass a timeout to client' do
      client = RasperClient::Client.new(host: 'localhost', port: @port,
        timeout: 100)
      expect(Net::HTTP).to \
        receive(:start).
        with('localhost', @port, read_timeout: 100).
        and_return(double(body: '{"success":true}'))
      client.add(name: 'programmers', content: jrxml_content)
    end
  end

  it 'empties all nil values' do
    client = RasperClient::Client.new(host: 'localhost', port: @port, empty_nil_values: true)
    client.generate(
      name: 'programmers',
      data: [
        { name: nil, software: nil },
        { name: nil, software: nil },
        { name: nil, software: nil }
      ],
      parameters: {
        'CITY' => nil,
        'DATE' => nil
      }
    )
    expect(RasperClient::FakeServer.last_generated_report).to eq \
      'name' => 'programmers',
      'data' => [
        { 'name' => '', 'software' => '' },
        { 'name' => '', 'software' => '' },
        { 'name' => '', 'software' => '' }
      ],
      'parameters' => {
        'CITY' => '',
        'DATE' => ''
      }
  end
end
