require 'pushpop-keen'
require 'pushpop-sendgrid'

TEMPLATES_DIR = File.expand_path('../', __FILE__)

PUSHPOP_FROM_EMAIL = ENV['PUSHPOP_FROM_EMAIL']
PUSHPOP_TO_EMAIL   = ENV['PUSHPOP_TO_EMAIL']
KEEN_COLLECTION = ENV['KEEN_COLLECTION'] || 'checks'

job 'alert if check has failed in the last minute' do

  every 1.minute

  step 'continue only if email addresses are set' do
    PUSHPOP_FROM_EMAIL && PUSHPOP_TO_EMAIL
  end

  keen 'query for failures' do
    event_collection  KEEN_COLLECTION
    analysis_type     'count'
    timeframe         'last_minute'
    group_by          'check.name'
    filters           [{ property_name: 'response.successful',
                         operator: 'eq',
                         property_value: false }]
  end

  step 'filter for at least 1 failure' do |response, _|
    response.select do |group|
      group['result'] > 0
    end
  end

  sendgrid 'send 1 email for each failure' do |response, _|
    response.each do |group|
      check_name = group['check.name']
      num_failures = group['result']
      send_email(PUSHPOP_TO_EMAIL, PUSHPOP_FROM_EMAIL,
                 "[pingpong] #{check_name} has failed!",
                 template("detect_failures_job.html.erb", group, _, TEMPLATES_DIR), nil)
    end
  end

end
