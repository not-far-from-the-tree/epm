FactoryGirl.define do

  factory :event do
    start { rand(100).days.from_now.change hour: rand(12)+7 }
    finish { (start || Time.now) + (rand(4)+1).hours }
  end

  factory :past_event, class: Event do
    start { (rand(100)+1).days.ago.change hour: rand(12)+7 }
    finish { start + (rand(4)+1).hours }
  end

end