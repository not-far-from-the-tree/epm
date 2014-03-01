FactoryGirl.define do

  factory :user do

    email { (65 + rand(26)).chr + Faker::Internet.free_email }
    password { Faker::Internet.password }
    # password confirmation is only checked if a confirmation is attempted. decided this is okay

    factory :admin do
      roles_attributes [name: :admin]
    end

    factory :coordinator do
      roles_attributes [name: :coordinator]
    end

    factory :participant do
      roles_attributes [name: :participant]
    end

    factory :full_user do
      name { Faker::Name.name }
      email { Faker::Internet.free_email(name) }
      description { Faker::Lorem.sentences(rand 1..5).join('. ') }
      phone { Faker::PhoneNumber.phone_number }
    end

  end

end