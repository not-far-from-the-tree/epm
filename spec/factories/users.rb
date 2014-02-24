FactoryGirl.define do

  factory :user do

    email { Faker::Internet.free_email }
    password { Faker::Internet.password }
    # password confirmation is only checked if a confirmation is attempted. decided this is okay

    factory :admin do
      roles_attributes [name: :admin]
    end

    factory :participant do
      roles_attributes [name: :participant]
    end

  end

end