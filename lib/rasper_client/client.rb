require 'net/http'
require 'base64'
require 'json'

module RasperClient
  class Client
    def initialize(host:, port:, timeout: nil, empty_nil_values: false)
      @host = host
      @port = port
      @timeout = timeout
      @empty_nil_values = empty_nil_values
      @request_params = build_request_params
    end

    def add(options)
      symbolize_keys(options)
      encode_options(options)
      response = execute_request(:add, options)
      JSON.parse(response.body) == { 'success' => true }
    end

    def generate(options)
      symbolize_keys(options)
      empty_nil_values(options) if @empty_nil_values
      options = encode_data(options)
      response = execute_request(:generate, options)
      result = JSON.parse(response.body)
      Base64.decode64(result['content'])
    end

    private

    def execute_request(action, options)
      Net::HTTP.start(*@request_params) do |http|
        request = Net::HTTP::Post.new(uri_for(action))
        request.body = options.to_json
        http.request(request)
      end
    end

    def build_request_params
      params = [@host, @port]
      params << { read_timeout: @timeout } if @timeout
      params
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

    def empty_nil_values(hash)
      hash.each_key do |key|
        if hash[key].is_a?(Hash)
          empty_nil_values(hash[key])
        elsif hash[key].is_a?(Array)
          hash[key].each {|item| empty_nil_values(item) if item.is_a?(Hash) }
        else
          hash[key] = '' if hash[key].nil?
        end
      end
    end

    def uri_for(action)
      "http://#{@host}:#{@port}/#{action}"
    end
  end
end
