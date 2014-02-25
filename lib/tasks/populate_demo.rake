namespace :db do
  task :populate_demo => :environment do

    # users
    # first user is automatically an admin, others are participants
    40.times do
      u = FactoryGirl.build :user
      u.skip_confirmation! # don't send emails
      u.save
    end

    def output_sometimes(val, percentage)
      ((rand * 100) <= percentage) ? val : nil
    end

    def rand_name
      Faker::Lorem.words(rand(3)+2).join(' ').capitalize
    end
    def rand_desc
      Faker::Lorem.sentences(rand(4)+1).join('. ')
    end

    # events and participants
    # past events
    20.times do
      e = FactoryGirl.create :past_event, name: output_sometimes(rand_name, 90), description: output_sometimes(rand_desc, 30)
      User.all.sample(rand(4) + 3).each do |u|
        e.event_users.create user: u
      end
    end
    # future events
    20.times do
      e = FactoryGirl.create :event, name: output_sometimes(rand_name, 90), description: output_sometimes(rand_desc, 30)
      User.all.sample(rand(7)).each do |u|
        e.event_users.create user: u
      end
    end

  end
end