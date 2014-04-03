FactoryGirl.define do

  factory :event do
    start { rand(1..100).days.from_now.change hour: rand(7..19) }
    duration { rand(1..5).hours }
    status Event.statuses[:approved]

    factory :participatable_event do
      coordinator
    end

    factory :proposed_event do
      status Event.statuses[:proposed]
    end

    factory :cancelled_event do
      status Event.statuses[:cancelled]
    end

    factory :full_event do
      name { Faker::Lorem.words(rand 2..5).join(' ').capitalize }
      description { Faker::Lorem.sentences(rand 1..5).join(' ') }
      notes { Faker::Lorem.sentences(rand 1..5).join(' ') }
      address { "#{Faker::Address.street_address}\n#{Faker::Address.city}, #{Faker::Address.country}" }
      lat { Faker::Address.latitude }
      lng { Faker::Address.longitude }
      min { rand(0..10) }
      max { rand(0..20)==20 ? nil : min + rand(0..20) }
    end

  end

  factory :past_event, class: Event do
    start { (rand(100)+1).days.ago.change hour: rand(7..19) }
    duration { rand(1..5).hours }

    factory :full_past_event do
      name { Faker::Lorem.words(rand 2..5).join(' ').capitalize }
      description { Faker::Lorem.sentences(rand 1..5).join(' ') }
      notes { Faker::Lorem.sentences(rand 1..5).join(' ') }
      address { "#{Faker::Address.street_address}\n#{Faker::Address.city}, #{Faker::Address.country}" }
      lat { Faker::Address.latitude }
      lng { Faker::Address.longitude }
    end

    factory :participatable_past_event do
      coordinator
      status Event.statuses[:approved]
    end

  end

end