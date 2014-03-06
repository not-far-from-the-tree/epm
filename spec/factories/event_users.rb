FactoryGirl.define do
  factory :event_user do
    association :event, factory: :participatable_event
    user
  end
end
