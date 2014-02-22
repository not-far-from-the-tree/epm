FactoryGirl.define do

  factory :admin_role, class: Role do
    user
    name Role.names[:admin]
  end

  factory :coordinator_role, class: Role do
    user
    name Role.names[:coordinator]
  end

  factory :participant_role, class: Role do
    user
    name Role.names[:participant]
  end

end