class CheckScheduler

  class << self

    def run(config)
      prepare(config)
      config.logger.info('CheckSchedulerStarting')

      begin
        clock = 0
        while true
          checks = config.check_source.all(config)
          checks.each do |check|
            if should_run_check(check, clock)
              run_iteration(config, check)
            end
          end
          clock = clock + 1
          sleep 1
        end
      rescue => e
        config.logger.error(e)
        config.logger.error('CheckSchedulerErrored; exiting')
      end

      shutdown
    end

    def run_once(config, filters)
      prepare(config)

      checks = config.check_source.all(config)
      checks.each do |check|
        should_run = filters.nil? || filters.all? do |name, value|
          check[name.to_sym].to_s == value[0]
        end
        if should_run
          run_iteration(config, check)
        end
      end

      shutdown
    end

    private

    def should_run_check(check, clock)
      clock % check.frequency == 0
    end

    def run_iteration(config, check)
      begin
        config.check_runner.run_check(config, check) do |start_time, duration, status, response|

          config.logger.info("CheckComplete, #{check.name}, #{status}, #{duration}")
          config.logger.debug(response)

          begin
            config.check_logger.log(config,
                                    check,
                                    config.check_marshaller.to_properties(
                                        config, check, start_time, duration, status, response))
          rescue => e
            config.logger.error("CheckLoggingFailed for #{check.name}")
            config.logger.error(e)
          end
        end

      rescue => e
        config.logger.error("CheckRunningFailed for #{check.name}")
        config.logger.error(e)
      end
    end

    def prepare(config)
      config.check_runner.prepare if defined? config.check_runner.prepare
      trap(:TERM) { shutdown }
      trap(:INT) { shutdown }
    end

    def shutdown
      config.check_runner.shutdown if defined? config.check_runner.shutdown
      exit
    end
  end
end
