FactoryGirl.define do
  factory :event_user do
    association :event, factory: :participatable_event
    user
    status EventUser.statuses[:attending]
  end
end
