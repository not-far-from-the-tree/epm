require 'spec_helper'

describe Role do

  it "has a valid factory" do
    expect(create(:participant_role)).to be_valid
  end

  it "is invalid without a name" do
    expect(build(:participant_role, name: nil)).not_to be_valid
  end

  it "does not allow duplicates" do
    u = create :user, no_roles: true
    u.roles.create name: :participant
    expect(u.roles.build(name: :participant)).not_to be_valid
  end

  it "prevents deleting admin role when there are no other admins" do
    User.delete_all # todo: database cleaner should handle this but apparently not
    admin = create :admin_role
    expect(admin.destroy).to be_false
  end

  it "removes the user from events they are coordinating upon losing coordinator role" do
    c = create :coordinator
    e1 = create :past_event, coordinator: c
    e2 = create :event, coordinator: c
    e3 = create :event, coordinator: c, status: :cancelled
    expect(Event.where(coordinator_id: c.id).length).to eq 3 # can't use c.coordinating_events as that excludes cancelled events
    c.roles.destroy_all
    events = Event.where(coordinator_id: c.id).reload
    expect(events.length).to eq 2
    expect(events).not_to include e2
  end

  it "adjusts event_users accordingly for users whos participant role is removed" do
    p = create :participant
    p2 = create :participant
    c = create :coordinator
    e_attending = create :participatable_event, coordinator: c
    eu1 = e_attending.attend p
    e_attending.attend p2
    e_cancelled = create :participatable_event, coordinator: c
    eu2 = e_cancelled.attend p
    e_cancelled.update status: :cancelled
    e_past = create :participatable_event, coordinator: c
    eu3 = e_past.attend p
    e_past.update start: 1.month.ago, finish: 1.week.ago
    e_invited = create :participatable_event, coordinator: c
    eu4 = e_invited.event_users.create user: p, status: :invited
    e_waitlisted = create :participatable_event, coordinator: c, max: 0
    eu5 = e_waitlisted.attend p
    expect(p.event_users.length).to eq 5
    ActionMailer::Base.deliveries.clear
    p.roles.destroy_all
    expect(eu1.reload.denied?).to be_true
    expect(eu2.reload.attending?).to be_true
    expect(eu3.reload.attending?).to be_true
    expect(eu4.reload.denied?).to be_true
    expect(eu5.reload.denied?).to be_true
    expect(e_attending.participants).to eq [p2] # make sure we're not getting rid of other users's EventUser records
    expect(ActionMailer::Base.deliveries.size).to eq 1 # sent emails about the one event that was being attended and no longer is
    expect(last_email.bcc).to include p.email
    expect(last_email.subject.downcase).to match 'no longer attending'
  end

  it "adjusts event_users accordingly for users whos participant role is removed by themselves" do
    p = create :participant
    c = create :coordinator
    e_attending = create :participatable_event, coordinator: c
    eu1 = e_attending.attend p
    e_cancelled = create :participatable_event, coordinator: c
    eu2 = e_cancelled.attend p
    e_cancelled.update status: :cancelled
    e_past = create :participatable_event, coordinator: c
    eu3 = e_past.attend p
    e_past.update start: 1.month.ago, finish: 1.week.ago
    e_invited = create :participatable_event, coordinator: c
    eu4 = e_invited.event_users.create user: p, status: :invited
    e_waitlisted = create :participatable_event, coordinator: c, max: 0
    eu5 = e_waitlisted.attend p
    expect(p.event_users.length).to eq 5
    ActionMailer::Base.deliveries.clear
    role = p.roles.first
    role.destroyed_by_self = true
    role.destroy
    expect(eu1.reload.cancelled?).to be_true
    expect(eu2.reload.attending?).to be_true
    expect(eu3.reload.attending?).to be_true
    expect(eu4.reload.not_attending?).to be_true
    expect(eu5.reload.withdrawn?).to be_true
    expect(ActionMailer::Base.deliveries.size).to eq 0 # no need to send emails when removing one's own role
  end

end