require 'pushpop'
require 'pushpop-keen'
require 'pushpop-sendgrid'
require 'dotenv'
Dotenv.load
require 'pushpop-slack'

require 'sinatra'
require 'sinatra/activerecord'
set :database_file, File.dirname(__FILE__) + "/../database.yml"

require './pingpong_config'
config = PingpongConfig

require File.dirname(__FILE__) + "/../lib/check.rb"

KEEN_COLLECTION = ENV['KEEN_COLLECTION'] || 'checks'

job 'run_checks' do

  every 1.minute

  step 'get checks to process' do
    time = Time.now
    minute = time.min + (time.hour * 60)

    Check.all.reject{|check| minute % check.frequency != 0}
  end

  step 'run checks' do |checks|
    checks_with_incidents = []

    checks.each do |check|
      check_response = nil

      begin
        config.check_runner.run_check(config, check) do |start_time, duration, response|
          #log_check(config, check, start_time, duration, response)
          check_response = response
          config.logger.info("CheckComplete, #{check.name}, #{duration}")
          config.logger.debug(response)

          if check_response[:had_incident]
            checks_with_incidents.push(check)
          end

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
        config.logger.info("  Error Message: #{e.message}")
        config.logger.debug(check_response)
      end
    end

    checks_with_incidents
  end

  sendgrid 'send emails' do |response, step_responses|
    if !response.empty?
      response.each do |check|
        if (check.is_bad?) || (check.is_warn? && check.email_warn)
          config.logger.info("sending email for #{check.name}")
          incident = Incident.most_recent_for_check(check, 1).first
          subject = incident.notification_subject
          body = incident.notification_body

          send_email config.properties[:to_email_address], config.properties[:from_email_address], subject, body, nil
        end
      end
      true
    else
      false
    end
  end

  slack 'send slack message' do |response, step_responses|
    step_responses['run checks'].each_with_index do |check, index|
      if (check.is_bad? && check.slack_bad) || (check.is_warn? && check.slack_warn)
        config.logger.info("sending slack message for #{check.name}")
        incident = Incident.most_recent_for_check(check, 1).first

        slack_attachment = {
          fallback: "Attachment couldn't be displayed - your client only supports plaintext",
          color: check.is_bad? ? config.properties[:slack][:bad_color] : config.properties[:slack][:warn_color],
          title: check.name,
          title_link: check.url,
          mrkdwn_in: ['fields'],
          fields: [
            {
              title: 'URL',
              value: check.url,
              short: true
            },
            {
              title: 'Severity',
              value: check.is_bad? ? 'Failure' : 'Warning',
              short: true
            },
            {
              title: 'Check Response',
              value: "```#{JSON.pretty_generate(incident.check_response)}```"
            }
          ]
        } 


        channel config.properties[:slack][:channel] if config.properties[:slack][:channel]
        username config.properties[:slack][:username]
        icon config.properties[:slack][:icon] if config.properties[:slack][:icon]
        message incident.notification_subject
        attachment slack_attachment

        send_message
      end 
    end
      # pushpop-slack calls send_message internally at the end of the step
      # so if we set the message to nil it will just abort rather than duplicate the last check message
      self._message = nil
  end
end
