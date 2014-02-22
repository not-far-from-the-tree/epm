namespace :db do
  task :populate_demo => :environment do

    # users
    # first user is automatically an admin, others are participants
    40.times do
      u = FactoryGirl.build :user
      u.skip_confirmation! # don't send emails
      u.save
    end

    # events and participants
    # past events
    20.times do
      e = FactoryGirl.create :past_event
      User.all.sample(rand(4) + 3).each do |u|
        e.event_users.create user: u
      end
    end
    # future events
    20.times do
      e = FactoryGirl.create :event
      User.all.sample(rand(7)).each do |u|
        e.event_users.create user: u
      end
    end

  end
end