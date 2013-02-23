require 'net/http'
require 'base64'

module RasperClient
  class Client
    def initialize(options)
      @host, @port = options.values_at(:host, :port)
    end

    def add(options)
      symbolize_keys(options)
      prepare_options(options)
      response = execute_request(:add, options)
      JSON.parse(response.body) == { 'success' => true }
    rescue Errno::ECONNREFUSED
      raise ConnectionRefusedError
    end

    def generate(options)
      symbolize_keys(options)
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
      symbolize(options, :name)
      symbolize(options, :content)
      symbolize(options, :images)
      symbolize(options, :report)
      symbolize(options, :data)
      symbolize(options, :parameters)
      if options[:images]
        options[:images].each do |image|
          symbolize(image, :name)
          symbolize(image, :content)
        end
      end
    end

    def symbolize(hash, key)
      hash[key.to_sym] = hash.delete(key.to_s) if hash.has_key?(key.to_s)
    end

    def prepare_options(options)
      options[:content] = Base64.encode64(options[:content])
      if options[:images]
        options[:images].each do |image|
          image[:content] = Base64.encode64(image[:content])
        end
      end
    end

    def uri_for(action)
      "http://#{@host}:#{@port}/#{action}"
    end
  end
end