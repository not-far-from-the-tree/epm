namespace :db do
  task :populate_demo => :environment do

    40.times do
      u = FactoryGirl.build :user
      u.skip_confirmation! # don't send emails
      u.save
    end

    10.times do
      e = FactoryGirl.create :event
      User.all.sample(rand(8)).each do |u|
        e.event_users.create user: u
      end
    end

  end
end