class EnvironmentAwareCheckMarshaller

  class << self

    def to_properties(config, check, start_time, duration, response)
      properties = {
        :check => check.to_hash,
        :request => {
            :sent_at => start_time.utc,
            :duration => duration
        },
        :response => response,
        :environment => {
          :rack_env => ENV['RACK_ENV']
        }
      }

      if env_properties = config[:environment]
        properties[:environment].merge!(env_properties)
      end

      remove_nils(properties)

      # handle the incident checking stuff
      check.add_response_time(duration)
      check.add_response_code(response[:status])
      check.check_for_incidents(response)
      check.save

      properties
    end

    def remove_nils(h)
      h.each do |k, v|
        if v.is_a?(Hash)
          remove_nils(v)
        else
          if v.nil?
            h.delete(k)
          end
        end
      end
    end

  end
end
