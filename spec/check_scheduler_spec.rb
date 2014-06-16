require 'spec_helper'

describe CheckScheduler do
  let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }

  describe 'run_check_if_its_time' do
    it 'runs the check if the modulus is 0' do
      expect(CheckScheduler.send(:should_run_check, check, 0)).to be_true
    end

    it 'runs the check if the modulus is 5' do
      expect(CheckScheduler.send(:should_run_check, check, 5)).to be_false
    end

    it 'runs the check if the modulus is 10' do
      expect(CheckScheduler.send(:should_run_check, check, 10)).to be_true
    end
  end

end
