require 'net/http'

module RasperClient
  class Client
    def initialize(options)
      @host, @port = options.values_at(:host, :port)
    end

    def add(options)
      Net::HTTP.start(@host, @port) do |http|
        request = Net::HTTP::Post.new(uri_for(:add))
        request.body = options.to_json
        http.request(request)
      end
    rescue Errno::ECONNREFUSED
      raise ConnectionRefusedError
    end

    private

    def uri_for(action)
      "#{@host}:#{@port}/#{action}"
    end
  end
end