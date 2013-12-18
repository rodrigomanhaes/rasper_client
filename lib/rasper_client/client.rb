require 'net/http'
require 'base64'
require 'json'

module RasperClient
  class Client
    def initialize(options)
      @host, @port = options.values_at(:host, :port)
    end

    def add(options)
      symbolize_keys(options)
      encode_options(options)

      response = execute_request(:add, options)

      JSON.parse(response.body) == { 'success' => true }
    rescue Errno::ECONNREFUSED
      raise ConnectionRefusedError
    end

    def generate(options)
      symbolize_keys(options)
      options = encode_data(options)
      response = execute_request(:generate, options)
      result = JSON.parse(response.body)
      Base64.decode64(result['content'])
    end

    private

    def execute_request(action, options)
      Net::HTTP.start(@host, @port) do |http|
        request = Net::HTTP::Post.new(uri_for(action))
        request.body = options.to_json
        http.request(request)
      end
    end

    def symbolize_keys(options)
      %w(name content images report data parameters).each do |s|
        symbolize_key(options, s)
      end
      if options[:images]
        options[:images].each do |image|
          symbolize_key(image, :name)
          symbolize_key(image, :content)
        end
      end
    end

    def symbolize_key(hash, key)
      hash[key.to_sym] = hash.delete(key.to_s) if hash.has_key?(key.to_s)
    end

    def encode_options(options)
      options[:content] = Base64.encode64(options[:content]) if options[:content]
      if options[:images]
        options[:images].each do |image|
          image[:content] = Base64.encode64(image[:content])
        end
      end
    end

    def encode_data(options)
      { data: Base64.encode64(options.to_json) }
    end

    def uri_for(action)
      "http://#{@host}:#{@port}/rasper_server/#{action}"
    end
  end
end
