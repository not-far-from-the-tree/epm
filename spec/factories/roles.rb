FactoryGirl.define do

  factory :role do
    association :user, factory: :roleless_user

    factory :admin_role do
      name Role.names[:admin]
    end

    factory :coordinator_role do
      name Role.names[:coordinator]
    end

    factory :participant_role do
      name Role.names[:participant]
    end

  end

end