require 'spec_helper'

describe CheckScheduler do
  let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }

  describe 'run_check_if_its_time' do
    it 'should run the check if the modulus is 0' do
      CheckScheduler.send(:should_run_check, check, 0).should be_true
    end

    it 'should run the check if the modulus is 5' do
      CheckScheduler.send(:should_run_check, check, 5).should be_false
    end

    it 'should run the check if the modulus is 10' do
      CheckScheduler.send(:should_run_check, check, 10).should be_true
    end
  end

end
