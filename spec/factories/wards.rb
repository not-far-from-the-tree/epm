FactoryGirl.define do

  factory :ward do
    name { Faker::Lorem.words(rand 2..3).join(' ').titlecase }
  end

end
