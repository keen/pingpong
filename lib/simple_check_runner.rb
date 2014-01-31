require 'uri'
require 'net/http'

class SimpleCheckRunner

  class << self
    def run_check(config, check, &block)
      uri = URI(check[:url])
      start_time = Time.now
      response = get_http(uri).request_get(uri)
      duration = Time.now - start_time
      block.yield(start_time, duration, response.code, response.to_hash)
    end

    def get_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        require 'net/https'
        http.use_ssl = true;
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.verify_depth = 5
        http.ca_file = File.expand_path('../../cacert.pem', __FILE__)
      end
      http
    end
  end
end
