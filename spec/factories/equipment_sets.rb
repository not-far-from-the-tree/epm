FactoryGirl.define do
  factory :equipment_set do

    factory :full_equipment_set do
      title { Faker::Lorem.words(rand 2..5).join(' ').capitalize }
      description { Faker::Lorem.sentences(rand 1..5).join(' ') }
    end

    factory :short_equipment_set do
      title { Faker::Lorem.words(rand 2..5).join(' ').capitalize }
      description { "" }
    end

  end

end
