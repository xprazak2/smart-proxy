require 'proxy/request'
require 'socket'

module Proxy
  class StartupInfo < Proxy::HttpRequest::ForemanRequest
    include Proxy::Log

    def post_features
      params = { :startup_refresh => true }.to_json
      # req = request_factory.create_post("/api/v2/smart_proxies/startup_refresh", params)
      response = send_request(params)
      logger.warn "Failed to notify Foreman on startup. Received response: #{response.code} #{response.msg}" unless response.code == "200"
      response
    end

    def path
      "/api/v2/smart_proxies/startup_refresh"
    end

    def send_request(body)
      req = Net::HTTP::Post.new(URI.join(uri.to_s, path).path)
      req.add_field('Accept', 'application/json,version=2')
      req.content_type = 'application/json'
      req.body = body
      http.request(req)
    end
  end
end
