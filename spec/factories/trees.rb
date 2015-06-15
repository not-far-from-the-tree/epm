FactoryGirl.define do
  factory :tree do
  	species { Tree.types[rand(0..(Tree.types.length-1))] }
	trait :owner do
	    owner do
	      FactoryGirl.create(:participant)
	    end
	end
    factory :full_tree do
    	subspecies { Faker::Lorem.words(rand 1..2).join(' ').capitalize }
		treatment { Faker::Lorem.sentences(rand 1..5).join(' ') }
		keep { rand(0..2) }
		additional { Faker::Lorem.sentences(rand 1..5).join(' ') }
		height { rand(1..4) }

	    factory :not_pickable_tree do
	      	pickable { false }
			not_pickable_reason { Faker::Lorem.sentences(rand 1..5).join(' ') }
	    end
	    factory :propertyowner_tree do
		      relationship { Tree.relationships[:propertyowner] }
		end
		factory :friend_tree do
		      relationship { Tree.relationships[:friend] }
		end
		factory :tenant_tree do
		      relationship { Tree.relationships[:tenant] }
		end
    end

    factory :short_tree do
    end

  end

end
