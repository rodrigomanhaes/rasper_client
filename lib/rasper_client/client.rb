require 'net/http'
require 'base64'
require 'json'
require 'uri'

module RasperClient
  class Client
    def initialize(options)
      @host, @port, @timeout = options.values_at(:host, :port, :timeout)
      @request_params = build_request_params
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
      if action == :generate
        boundary = "AaB03x"
        uri = URI.parse(uri_for(action))
        post_body = []
        post_body << "--#{boundary}\r\n"
        post_body << "Content-Disposition: form-data; name=\"datafile\"; filename=\"data.json\"\r\n"
        post_body << "Content-Type: application/json\r\n"
        post_body << "\r\n"
        post_body << options.to_json
        post_body << "\r\n--#{boundary}--"

        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = post_body.join
        request["Content-Type"] = "multipart/form-data, boundary=#{boundary}"

        http.request(request)
      else
        Net::HTTP.start(*@request_params) do |http|
          request = Net::HTTP::Post.new(uri_for(action))
          request.body = options.to_json
          http.request(request)
        end
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

    def uri_for(action)
      "http://#{@host}:#{@port}/#{action}"
    end
  end
end
