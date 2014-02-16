FactoryGirl.define do
  factory :event do
    start { Time.now }
    finish { Time.now + 3.hours }
  end
end