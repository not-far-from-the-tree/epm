namespace :db do
  task :populate_demo => :environment do

    # probability that a record would have a particular attribute
    event_attribute_probabilities = {name: 80, description: 30}
    user_attribute_probabilities = {name: 90, description: 10, phone: 40}
    def use_probabilities(record, attr_prob)
      attr_prob.each do |k, prob|
        record.send("#{k}=", nil) if (rand * 100) > prob
      end
      record.save
      record
    end

    # users
    # first user is automatically an admin, others are participants
    40.times do
      u = FactoryGirl.build :full_user
      u.skip_confirmation! # don't send emails
      use_probabilities(u, user_attribute_probabilities)
    end
    # handful of coordinators
    5.times do
      u = FactoryGirl.build :full_user
      u.skip_confirmation! # don't send emails
      u.roles.build name: :coordinator
      use_probabilities(u, user_attribute_probabilities)
    end

    # events and participants
    # past events
    30.times do
      e = FactoryGirl.build(:full_past_event)
      e.coordinator = User.coordinators.sample(1).first
      e = use_probabilities(e, event_attribute_probabilities)
      User.participants.sample(rand 3..7).each do |u|
        e.event_users.create user: u
      end
    end
    # future events
    20.times do
      e = FactoryGirl.build(:full_event)
      e.coordinator = User.coordinators.sample(1).first if rand < 0.5
      e = use_probabilities(e, event_attribute_probabilities)
      User.participants.sample(rand 7).each do |u|
        e.event_users.create user: u
      end
    end
    # events with a date but no coordinator
    2.times do
      e = FactoryGirl.build(:full_event)
      e = use_probabilities(e, event_attribute_probabilities)
    end
    event_attribute_probabilities[:name] = 100
    # events with a coordinator but no date
    2.times do
      e = FactoryGirl.build(:full_event, start: nil)
      e.coordinator = User.coordinators.sample(1).first
      e = use_probabilities(e, event_attribute_probabilities)
    end
    # events with no date or coordinator
    2.times do
      e = FactoryGirl.build(:full_event, start: nil)
      e = use_probabilities(e, event_attribute_probabilities)
    end

  end
end