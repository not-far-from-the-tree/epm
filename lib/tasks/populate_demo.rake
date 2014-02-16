namespace :db do
  task :populate_demo => :environment do

    20.times do
      u = FactoryGirl.build :user
      u.skip_confirmation! # don't send emails
      u.save
    end

    20.times { FactoryGirl.create :event }

  end
end