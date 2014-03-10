require 'em-http-request'
require 'multi_json'

class EventmachineCheckRunner

  class << self

    def run_check(config, check, &block)
      prepare

      start_time = Time.now
      em = EventMachine::HttpRequest.new(check.url, em_http_options(config))
      http = case check.method
      # Decide what method to use
      when "GET"
        em.get
      when "POST"
        em.post :body => check.data
      else
        # Note that this was vetted earlier, so this is just a conversative check
        raise "Invalid HTTP method '#{check.method}"
      end


      callback = Proc.new {
        duration = Time.now - start_time
        block.yield(start_time, duration, http.response_header.status, response_to_hash(config, check, http))
      }
      http.callback &callback
      http.errback &callback
      http
    end

    def response_to_hash(config, check, http)
      content_type = http.response_header['CONTENT_TYPE']
      basic_params = { :http_status => http.response_header.http_status,
        :http_reason => http.response_header.http_reason,
        :http_version => http.response_header.http_version,
        :date => http.response_header['DATE'],
        :server => http.response_header['SERVER'],
        :last_modified => http.response_header.last_modified,
        :content_length => http.response_header.content_length,
        :content_type => content_type,
        :location => http.response_header.location }

      if check.save_body
        if content_type && content_type =~ /application\/json/
          begin
            json_body = MultiJson.load(http.response)
            basic_params[:body] = json_body
          rescue => e
            config.logger.error(e)
            config.logger.error("Could not parse JSON response body for check #{check.name} - #{http.response}")
          end
        else
          config.logger.warn("Content type for #{check.name} is not JSON (it's #{content_type}) - body will not be saved")
        end
      end

      basic_params
    end

    def prepare
      EventMachine.error_handler do |e|
        puts "Error raised during event loop: #{e.message}"
      end
      ensure_em
    end

    def ensure_em
      unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
        Thread.new {
          EM.run
        }
        sleep 1
      end
    end

    def shutdown
      EM.stop_event_loop
      while EM.reactor_running?; sleep 1; end
    end

    private

    def em_http_options(config)
      { :connect_timeout => config[:check_runner_connect_timeout],
        :inactivity_timeout => config[:check_runner_inactivity_timeout] }
    end
  end
end
