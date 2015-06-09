FactoryGirl.define do
  factory :agency do

    factory :full_agency do
      title { Faker::Lorem.words(rand 2..5).join(' ').capitalize }
      description { Faker::Lorem.sentences(rand 1..5).join(' ') }
    end

    factory :short_agency do
      title { Faker::Lorem.words(rand 2..5).join(' ').capitalize }
      description { "" }
    end

  end

end
