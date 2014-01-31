require 'keen'

class KeenCheckLogger

  class << self

    attr_accessor :keen
    attr_accessor :collection

    def log(config, check, properties)

      if !config[:keen][:project_id]
        config.logger.warn("*** Keen IO environment variables are not set! Events will not be logged! See https://github.com/keenlabs/pingpong ***")
        return
      end

      unless keen
        ensure_em
        keen = keen_client(config)
        collection = config[:keen][:collection]
      end

      http = keen.publish_async(collection, properties)
      http.callback {
        config.logger.debug("CheckLoggingSucceeded, #{check.name}, #{properties.inspect}")
      }
      http.errback {
        config.logger.debug("CheckLoggingFailed, #{check.name}, #{properties.inspect}")
      }
      http
    end

    def keen_client(config)
        Keen::Client.new(
          :project_id => config[:keen][:project_id],
          :write_key => config[:keen][:write_key],
          :read_key => config[:keen][:read_key],
          :master_key => config[:keen][:master_key])
    end

    private

    def ensure_em
      unless EM.reactor_running?
        Thread.new {
          EM.run
        }
        sleep 1
      end
    end
  end
end
