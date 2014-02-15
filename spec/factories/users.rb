FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    # password confirmation is only checked if a confirmation is attempted. decided this is okay
  end
end