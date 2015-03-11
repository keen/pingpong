require 'spec_helper'

describe Check do
  subject { build(:check) }

  describe "#initialize" do
    context "missing required values" do
      it "should raise an error" do
        expect {
          Check.new(:name => 'Bob', :url => 'http://google.com').validate
        }.to raise_error

        expect {
          Check.new(:name => 'Bob', :frequency => 10).validate
        }.to raise_error

        expect {
          Check.new(:url => 'http://bob.com', :frequency => 10).validate
        }.to raise_error

        expect {
          Check.new(
            :name => 'foo',
            :url => 'http://keen.io',
            :frequency => 10,
            :method => "POST"
          ).validate
        }.to raise_error
      end
    end
  end

  describe ".to_hash" do
    it "produces a Hash" do
      expect(subject.to_hash.keys.sort).to eq([
        :custom_properties,
        :data,
        :frequency,
        :headers,
        :id,
        :method,
        :name,
        :save_body,
        :url
      ])
    end
  end

  describe ".add_response_time" do
    context "has no response times" do
      it 'creates response times array' do
        expect{subject.add_response_time(10)}.to change{subject.response_times}.from(nil).to([10])
      end
    end

    context "has 30 response times" do
      before { 35.times {subject.add_response_time(10)} }

      it 'only keeps the last 30' do
        expect(subject.response_times.length).to eq(30)
      end
    end
  end

  describe ".add_response_code" do
    context "has no response codes" do
      it 'creates response codes array' do
        expect{subject.add_response_code(200)}.to change{subject.response_codes}.from(nil).to([200])
      end
    end

    context "has 30 response codes" do
      before { 35.times {subject.add_response_code(200)} }

      it 'only keeps the last 30' do
        expect(subject.response_codes.length).to eq(30)
      end
    end
  end

  describe ".is_ok?" do
    context "there are no incidents" do
      it "is true" do
        expect(subject.is_ok?).to be_true
      end
    end

    context "there is one ok incident" do
      before { subject.incidents << build(:incident, :ok, check: subject) }

      it "is false" do
        expect(subject.is_ok?).to be_true
      end
    end

    context "there is one warn incident" do
      before { subject.incidents << build(:incident, :warn, check: subject) }

      it "is false" do
        expect(subject.is_ok?).to be_false
      end
    end

    context "there is one bad incident" do
      before { subject.incidents << build(:incident, :bad, check: subject) }

      it "is false" do
        expect(subject.is_ok?).to be_false
      end
    end
  end

  describe ".is_warn?" do
    context "there are no incidents" do
      it "is false" do
        expect(subject.is_warn?).to be_false
      end
    end

    context "there is one ok incident" do
      before { subject.incidents << build(:incident, :ok, check: subject) }

      it "is false" do
        expect(subject.is_warn?).to be_false
      end
    end

    context "there is one warn incident" do
      before { subject.incidents << build(:incident, :warn, check: subject) }

      it "is true" do
        expect(subject.is_warn?).to be_true
      end
    end

    context "there is one bad incident" do
      before { subject.incidents << build(:incident, :bad, check: subject) }

      it "is false" do
        expect(subject.is_warn?).to be_false
      end
    end
  end

  describe ".is_bad?" do
    context "there are no incidents" do
      it "is false" do
        expect(subject.is_bad?).to be_false
      end
    end

    context "there is one ok incident" do
      before { subject.incidents << build(:incident, :ok, check: subject) }

      it "is false" do
        expect(subject.is_bad?).to be_false
      end
    end

    context "there is one warn incident" do
      before { subject.incidents << build(:incident, :warn, check: subject) }

      it "is false" do
        expect(subject.is_bad?).to be_false
      end
    end

    context "there is one bad incident" do
      before { subject.incidents << build(:incident, :bad, check: subject) }

      it "is false" do
        expect(subject.is_bad?).to be_true
      end
    end
  end

  describe ".check_for_incidents" do
    let(:response) { {foo: "bar", time: 12.3} }

    context "there haven't been any checks" do
      it "creates no incidents" do
        subject.check_for_incidents(response)
        expect(subject.incidents).to be_empty
      end
    end

    context "there are many similar response times" do
      before { 10.times { subject.add_response_time(10) } }

      it "creates no incidents" do
        subject.check_for_incidents(response)
        expect(subject.incidents).to be_empty
      end
    end

    context "the most recent response time is slow" do
      before { 
        29.times { subject.add_response_time(10) }
        subject.add_response_time(15)
      }

      it "creates an incident" do
        expect {
          subject.check_for_incidents(response)
        }.to change{subject.incidents.length}.by(1)
      end

      it "creates a warning incident" do
        subject.check_for_incidents(response)
        expect(subject.incidents.last.incident_type).to eq(Incident::STATUS_WARN)
      end
    end

    context "the most recent response time is very slow" do
      before { 
        29.times { subject.add_response_time(10) }
        subject.add_response_time(20)
      }

      it "creates a bad incident" do
        subject.check_for_incidents(response)
        expect(subject.incidents.length).to eq(1)
        expect(subject.incidents.last.incident_type).to eq(Incident::STATUS_BAD)
      end
    end

    context "the response times are somewhat variable" do
      before {
        [5, 8, 2, 9, 7, 1, 4, 11, 6, 4, 6].each {|time| subject.add_response_time(time)}
      }

      it "creates a warn incident" do
        subject.check_for_incidents(response)
        expect(subject.incidents.length).to eq(1)
        expect(subject.incidents.last.info).to eq("Variance in response times volatile.")
      end
    end

    context "the response times are highly variable" do
      before {
        [5, 20, 2, 9, 30, 1, 4, 11, 6, 4, 46, 14].each {|time| subject.add_response_time(time)}
      }

      it "creates a bad incident" do
        subject.check_for_incidents(response)
        expect(subject.incidents.length).to eq(1)
        expect(subject.incidents.last.info).to eq("Variance in response times very volatile.")
      end
    end

    context "all response codes are 2xx's" do
      before {
        [200, 201, 202, 203, 204, 205, 206].each {|code| subject.add_response_code(code)}
      }

      it "doesn't create an incident" do
        subject.check_for_incidents(response)
        expect(subject.incidents).to be_empty
      end
    end

    context "most recent response code is a 3xx" do
      before {
        10.times { subject.add_response_code(200) }
        subject.add_response_code(301)
      }

      it "generates a warning" do
        subject.check_for_incidents(response)
        expect(subject.is_warn?).to be_true
      end
    end

    context "we get one 4xx back" do
      before {
        10.times { subject.add_response_code(200) }
        subject.add_response_code(400)
      }

      it "generates a warning" do
        subject.check_for_incidents(response)
        expect(subject.is_warn?).to be_true
      end
    end

    context "we get two 4xx's in a row" do
      before {
        10.times { subject.add_response_code(200) }
        [400, 403].each {|code| subject.add_response_code(code)}
      }

      it "is in a bad state" do
        subject.check_for_incidents(response)
        expect(subject.is_bad?).to be_true
      end
    end

    context "we get one 5xx back" do
      before {
        10.times { subject.add_response_code(200) }
        subject.add_response_code(500)
      }

      it "generates a warning" do
        subject.check_for_incidents(response)
        expect(subject.is_warn?).to be_true
      end
    end

    context "we get two 5xx's in a row" do
      before {
        10.times { subject.add_response_code(200) }
        [500, 503].each {|code| subject.add_response_code(code)}
      }

      it "is in a bad state" do
        subject.check_for_incidents(response)
        expect(subject.is_bad?).to be_true
      end
    end

    context "we had a warning for return code and now its good" do
      before {
        10.times { subject.add_response_code(200) }
        subject.add_response_code(300)
      }

      it "is ok" do
        subject.check_for_incidents(response)
        expect(subject.is_ok?).to be_false

        subject.add_response_code(200)
        subject.check_for_incidents(response)

        expect(subject.is_ok?).to be_true
        expect(subject.incidents.length).to eq(2)
      end
    end

    context "response times were wonky, now they're good" do
      before {
        29.times { subject.add_response_time(10) }
        subject.add_response_time(15)
      }

      it "is ok" do
        subject.check_for_incidents(response)
        expect(subject.is_ok?).to be_false

        subject.add_response_time(10)
        subject.check_for_incidents(response)
        expect(subject.is_ok?).to be_true
        expect(subject.incidents.length).to eq(2)
      end
    end

    context "response times are normal, then go up a bit" do
      before {
        28.times { subject.add_response_time(10) }
        subject.add_response_time(15)
      }

      it "generates one incident" do
        subject.check_for_incidents(response)
        subject.add_response_time(15)
        subject.check_for_incidents(response)

        expect(subject.incidents.length).to eq(1)
      end
    end
  end
end
