require 'pushpop'

FROM_EMAIL = 'pushpop-app@keen.io'
TO_EMAIL   = 'josh@keen.io'
COLLECTION = ENV['KEEN_COLLECTION']

job 'alert if check has failed in the last minute' do

  every 1.minute

  keen do
    event_collection  COLLECTION
    analysis_type     'count'
    timeframe         'last_minute'
    group_by          'check.name'
    filters           [{ property_name: 'response.successful',
                         operator: 'eq',
                         property_value: false }]
  end

  step 'isolate checks with at least 1 failure' do |response, _|
    response.select do |group|
      group['result'] > 0
    end
  end

  sendgrid 'send a text for each failing check' do |response, _|
    response.each do |group|
      check_name = group['check.name']
      num_failures = group['result']
      send_email(TO_EMAIL, FROM_EMAIL,
                 "[pingpong] #{check_name} has failed!",
                 "#{check_name} has failed #{num_failures} times")
    end
  end

end
