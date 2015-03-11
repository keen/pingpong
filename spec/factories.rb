FactoryGirl.define do
  factory :check do
    sequence(:name) { |n| "TestCheck#{n}" }
    url "www.google.com"
    frequency 1
    add_attribute(:method) { "GET" }
  end

  factory :incident do
    info "Test incident"
    incident_type Incident::STATUS_WARN

    trait :ok do
      incident_type Incident::STATUS_OK
    end

    trait :warn do
      incident_type Incident::STATUS_WARN
    end

    trait :bad do
      incident_type Incident::STATUS_BAD
    end

    after(:create) do |incident, evaluator|
      if evaluator.check
        incident.check = evaluator.check
      else
        incident.check = build(:check)
      end
    end
  end
end
