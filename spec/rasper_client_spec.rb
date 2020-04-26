require 'net/http'
require 'spec_helper'

describe RasperClient do
  let(:client) do
    options = {
      host: 'localhost',
      port: port,
      empty_nil_values: empty_nil_values,
      secure: secure
    }
    options[:timeout] = timeout if timeout
    if client_username && client_password
      options[:username] = client_username
      options[:password] = client_password
    end
    RasperClient::Client.new(**options)
  end
  let(:port) { 7888 }
  let!(:server) do
    RasperClient::FakeServer.new.start(port, server_username, server_password)
  end

  let(:server_username) { nil }
  let(:server_password) { nil }
  let(:client_username) { nil }
  let(:client_password) { nil }
  let(:timeout) { nil }
  let(:empty_nil_values) { false }
  let(:secure) { false }

  let(:jrxml_content) { File.read(resource('programmers.jrxml')) }
  let(:image_content) { File.read(resource('imagem.jpg')) }

  after { server.stop }

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
    expect(client.add(params)).to be true
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
    expect(client.add(params)).to be true
    last = RasperClient::FakeServer.last_added_report
    expect(last['name']).to be_nil
    expect(last['content']).to be_nil
    expect(last['images'].size).to eq 1
    image = last['images'][0]
    expect(image['name']).to eq 'imagem.jpg'
    expect(image['content']).to eq Base64.encode64(image_content)
  end

  it 'generates report' do
    pdf_content = client.generate(
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
    let(:timeout) { 100 }
    it 'allows pass a timeout to client' do
      expect(Net::HTTP).to \
        receive(:start).
        with('localhost', port, read_timeout: 100).
        and_return(double(body: '{"success":true}', code: '200'))
      client.add(name: 'programmers', content: jrxml_content)
    end
  end

  describe 'HTTPS support' do
    let(:secure) { true }
    before do
      allow(Net::HTTP).to receive(:start)
        .and_return(double(body: '{"success":true}', code: '200'))
    end
    it do
      client.add(name: 'programmers', content: jrxml_content)
      expect(Net::HTTP)
        .to have_received(:start)
        .with('localhost', port, use_ssl: true)
    end
  end

  describe 'HTTP basic auth' do
    let(:server_username) { 'serveruser' }
    let(:server_password) { 'serverpassword' }
    let(:client_username) { server_username }

    context 'with correct credentials' do
      let(:client_password) { server_password }
      it do
        expect { client.add(name: 'programmers', content: jrxml_content) }
          .not_to raise_error
      end
    end

    context 'with incorrect credentials' do
      let(:client_password) { SecureRandom.hex }
      it do
        expect { client.add(name: 'programmers', content: jrxml_content) }
          .to raise_error(RasperClient::Error, RasperClient::Error::INVALID_CREDENTIALS)
      end
    end
  end

  describe 'empties all nil values' do
    let(:empty_nil_values) { true }

    it do
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
end
