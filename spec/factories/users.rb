FactoryGirl.define do

  factory :user do
    fname { Faker::Name.first_name }
    lname { Faker::Name.last_name }
    email { Faker::Internet.free_email("#{fname} #{lname}") }
    phone { Faker::PhoneNumber.phone_number }
    password do
      pass = Faker::Internet.password
      pass += 'x' * [0, (7-pass.length)].max # ensures password is at least 7 characters, the min length
      pass
    end
    # password confirmation is only checked if a confirmation is attempted. decided this is okay

    factory :roleless_user do
      no_roles true
    end

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
      address { "#{Faker::Address.street_address}\n#{Faker::Address.city}, #{Faker::Address.country}" }
      lat { Faker::Address.latitude }
      lng { Faker::Address.longitude }
    end

  end

end