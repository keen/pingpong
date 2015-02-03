require 'pushpop'
require 'pushpop-keen'
require 'pushpop-sendgrid'

require 'dotenv'
Dotenv.load

require 'sinatra'
require 'sinatra/activerecord'
set :database_file, File.dirname(__FILE__) + "/../database.yml"

require './pingpong_config'
config = PingpongConfig

require File.dirname(__FILE__) + "/../lib/check.rb"

KEEN_COLLECTION = ENV['KEEN_COLLECTION'] || 'checks'

job do

  every 1.minute

  step 'get checks to process' do
    puts "HELLO THERE"
    time = Time.now
    minute = time.min + (time.hour * 60)

    Check.all.reject{|check| minute % check.frequency != 0}
  end

  step 'run checks' do |checks|
    checks.each do |check|
      check_response = nil

      begin
        config.check_runner.run_check(config, check) do |start_time, duration, response|
          #log_check(config, check, start_time, duration, response)
          check_response = response
          config.logger.info("CheckComplete, #{check.name}, #{duration}")
          config.logger.debug(response)

          begin
            config.check_logger.log(config,
                                    check,
                                    config.check_marshaller.to_properties(
                                        config, check, start_time, duration, response))
          rescue => e
            config.logger.error("CheckLoggingFailed for #{check.name}")
            config.logger.error(e)
          end
        end
      rescue => e
        config.logger.info("Check running failed for #{check.name}.")
        config.logger.debug(check_response)
      end
    end
  end
end
