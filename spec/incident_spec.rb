require 'spec_helper'

describe Incident do
  subject { build(:incident) }

  describe "#is_ok?" do
    context "incident is ok" do
      before { subject.incident_type = Incident::STATUS_OK }
      it "returns true" do
        expect(subject.is_ok?).to be_true
      end
    end

    context "incident is a warn" do
      before { subject.incident_type = Incident::STATUS_WARN }
      it "returns false" do
        expect(subject.is_ok?).to be_false
      end
    end

    context "incident is bad" do
      before { subject.incident_type = Incident::STATUS_BAD }
      it "returns false" do
        expect(subject.is_ok?).to be_false
      end
    end
  end

  describe "#is_warn?" do
    context "incident is ok" do
      before { subject.incident_type = Incident::STATUS_OK }
      it "returns false" do
        expect(subject.is_warn?).to be_false
      end
    end

    context "incident is a warn" do
      before { subject.incident_type = Incident::STATUS_WARN }
      it "returns true" do
        expect(subject.is_warn?).to be_true
      end
    end

    context "incident is bad" do
      before { subject.incident_type = Incident::STATUS_BAD }
      it "returns false" do
        expect(subject.is_warn?).to be_false
      end
    end
  end

  describe "#is_bad?" do
    context "incident is ok" do
      before { subject.incident_type = Incident::STATUS_OK }
      it "returns false" do
        expect(subject.is_bad?).to be_false
      end
    end

    context "incident is a warn" do
      before { subject.incident_type = Incident::STATUS_WARN }
      it "returns false" do
        expect(subject.is_bad?).to be_false
      end
    end

    context "incident is bad" do
      before { subject.incident_type = Incident::STATUS_BAD }
      it "returns true" do
        expect(subject.is_bad?).to be_true
      end
    end
  end
end
