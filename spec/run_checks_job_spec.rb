require 'spec_helper'

describe 'Pushpop' do
  # Find the correct job
  job = Pushpop.jobs.find { |job| 
    job.name == 'run_checks' 
  }

  describe 'job' do
    it 'has a job named run_checks'do
      expect(job.class).to equal(Pushpop::Job)
    end

    it 'runs every 1 minute' do
      expect(job.period).to eq(1.minute)
    end
  end

  describe 'steps' do
    describe 'get checks to process' do
      step = job.steps.find { |step|
        step.name == 'get checks to process' 
      }

      let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }

      it 'should have this step' do
        expect(step.class).to equal(Pushpop::Step) 
      end

      it 'should run steps with the correct frequency' do
        Check.stub(:all).and_return([check])

        # Should run on 10 minute intervals, so noon works`
        Time.stub(:now).and_return(Time.parse('2015-05-01 12:00:00 -0000'))
        expect(step.run.length).to equal(1)

        # Let's do 12:05 PM - that's not on a 10 minute interval
        Time.stub(:now).and_return(Time.parse('2015-05-01 12:05:00 -0000'))
        expect(step.run.length).to equal(0)
      end
    end

    describe 'send emails' do
      let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }
      let(:incident) { 
        Incident.new(
          :incident_type => 3,
          :info => 'test',
          :check_response => { :body => 'tester' },
          :check => check
        ) 
      } 


      step = job.steps.find { |step|
        step.name == 'send emails'
      }

      it 'should have this step' do
        expect(step.class).to equal(Pushpop::Sendgrid) 
      end
      
      it 'should send an email for bad checks' do
        check.stub(:is_bad?).and_return(true)
        Incident.stub(:most_recent_for_check).and_return([incident])

        step.should_receive(:send_email)

        step.run([check])
      end
      
      it 'should not send an email for warns' do
        check.stub(:is_bad?).and_return(false)
        check.stub(:is_warn?).and_return(true)
        Incident.stub(:most_recent_for_check).and_return([incident])

        step.should_not_receive(:send_email)

        step.run([check])
      end
      
      it 'should send warning emails if email_warn is true' do
        check.stub(:is_bad?).and_return(false)
        check.stub(:is_warn?).and_return(true)
        check.email_warn = true
        Incident.stub(:most_recent_for_check).and_return([incident])

        step.should_receive(:send_email)

        step.run([check])
      end
    end
    
    describe 'send slack message' do
      let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }
      let(:incident) {
        Incident.new(
          :incident_type => 3,
          :info => 'test',
          :check_response => { :body => 'tester' },
          :check => check
        )
      }
      let(:step_responses) { { 'run checks' => [check] }}

      before(:each) do
        allow(Incident).to receive(:most_recent_for_check).and_return([incident])
      end


      step = job.steps.find { |step|
        step.name == 'send slack message'
      }

      it 'should have this step' do
        expect(step.class).to equal(Pushpop::Slack)
      end

      it 'should not send any messages when the configs are false' do
        allow(check).to receive(:is_bad?).and_return(true)
        allow(check).to receive(:is_warn?).and_return(true)
        allow(check).to receive(:slack_bad).and_return(false)

        expect(step).not_to receive(:send_message)
        step.run(nil, step_responses)
      end

      it 'should send messages for bad checks if slack_bad is true' do
        allow(check).to receive(:is_bad?).and_return(true)
        allow(check).to receive(:slack_bad).and_return(true)

        expect(step).to receive(:send_message)
        step.run(nil, step_responses)
      end

      it 'should send messages for warn checks if slack_warn is true' do
        allow(check).to receive(:is_warn?).and_return(true)
        allow(check).to receive(:slack_warn).and_return(true)
        allow(check).to receive(:send_message)

        incident.incident_type = 2

        expect(step).to receive(:send_message)
        step.run(nil, step_responses)

        incident.incident_type = 2
      end

      it 'should send multiple messages if there are multiple bad checks' do
        allow(check).to receive(:is_bad?).and_return(true)
        allow(check).to receive(:slack_bad).and_return(true)

        expect(step).to receive(:send_message).exactly(2).times
        puts 'multiple'
        step.run(nil, { 'run checks' => [check, check] })
      end
    end
  end
end
