FactoryGirl.define do
  factory :user do
    email "foo@example.com"
    password "some_password" # password confirmation is only checked if a confirmation is attempted. decided this is okay
  end
end