require "spec_helper"

describe EventMailer do

  before :each do
    @event = create :participatable_event
  end

  context "from" do

    # from address is set globally. here we check a few of the mailers but don't bother with all

    it "sends attend mail from the right address" do
      mail = EventMailer.attend @event, create(:participant)
      expect(mail.from).to eq ['no-reply@example.com']
    end

    it "sends coordinator assigned mail from the right address" do
      mail = EventMailer.coordinator_assigned(@event)
      expect(mail.from).to eq ['no-reply@example.com']
    end

    it "sends canceled event mail from the right address" do
      mail = EventMailer.cancel(@event, @event.users)
      expect(mail.from).to eq ['no-reply@example.com']
    end

  end

  context "permissions" do

    # both tests use the change() mailer, which is fine as all mailes which show an event use the same _event partial

    it "shows notes to those who have access" do
      @event.notes = 'some note'
      mail = EventMailer.change @event, [@event.coordinator]
      mail.body.parts.each do |part|
        expect(part.to_s).to match 'some note'
      end
    end

    it "does not show notes to those who do not have access" do
      @event.notes = 'some note'
      participant = create :participant
      @event.event_users.create user: participant
      mail = EventMailer.change @event, [participant]
      mail.body.parts.each do |part|
        expect(part.to_s).not_to match 'some note'
      end
    end

  end

  it "sends correct attend emails" do
    participant = create :participant
    mail = EventMailer.attend(@event, participant)
    expect(mail.to.length).to eq 1
    expect(mail.to.first).to match participant.email
    expect(mail.subject).to eq 'You have joined an event'
    # checks that there is both email and plain text, and they both have the right content
    expect(mail.body.parts.length).to eq 2
    mail.body.parts.each do |part|
      expect(part.to_s).to match event_url(@event)
    end
  end

  it "sends correct emails when a coordinator is assigned" do
    mail = EventMailer.coordinator_assigned(@event)
    expect(mail.to.length).to eq 1
    expect(mail.to.first).to match @event.coordinator.email
    expect(mail.subject).to eq 'You have been assigned an event'
    # checks that there is both email and plain text, and they both have the right content
    expect(mail.body.parts.length).to eq 2
    mail.body.parts.each do |part|
      expect(part.to_s).to match event_url(@event)
    end
  end

  context "event cancelled" do

    it "sends correct emails to admins/coordinator when an event is cancelled" do
      @event.cancel_description = 'bad weather'
      @event.cancel_notes = 'blabla'
      mail = EventMailer.cancel(@event, [@event.coordinator])
      expect(mail.to).to be_nil
      expect(mail.bcc.length).to eq 1
      expect(mail.bcc.first).to match @event.coordinator.email
      expect(mail.subject).to match 'cancelled'
      # checks that there is both email and plain text, and they both have the right content
      expect(mail.body.parts.length).to eq 2
      mail.body.parts.each do |part|
        expect(part.to_s).to match 'cancelled'
        expect(part.to_s).to match 'bad weather'
        expect(part.to_s).to match 'blabla'
      end
    end

    it "sends correct emails to admins/coordinator when an event is cancelled" do
      @event.cancel_description = 'bad weather'
      @event.cancel_notes = 'blabla'
      participant = create :participant
      mail = EventMailer.cancel(@event, [participant])
      expect(mail.to).to be_nil
      expect(mail.bcc.length).to eq 1
      expect(mail.bcc.first).to match participant.email
      expect(mail.subject).to match 'cancelled'
      # checks that there is both email and plain text, and they both have the right content
      expect(mail.body.parts.length).to eq 2
      mail.body.parts.each do |part|
        expect(part.to_s).to match 'cancelled'
        expect(part.to_s).to match 'bad weather'
        expect(part.to_s).not_to match 'blabla'
      end
    end

  end

  it "sends correct emails when an event is changed" do
    mail = EventMailer.change(@event, @event.users)
    expect(mail.to).to be_nil
    expect(mail.bcc.length).to eq @event.users.length
    expect(mail.bcc.first).to match @event.users.first.email
    expect(mail.subject.downcase).to match 'changes'
    # checks that there is both email and plain text, and they both have the right content
    expect(mail.body.parts.length).to eq 2
    mail.body.parts.each do |part|
      expect(part.to_s).to match 'changes'
      expect(part.to_s).to match event_url(@event)
    end
  end

  it "sends correct emails when an event is changed to be ready for approval" do
    create :admin # make sure there's at least one admin
    event = create :event, status: :proposed, coordinator: create(:coordinator)
    mail = EventMailer.awaiting_approval(event, User.admins)
    expect(mail.to).to be_nil
    expect(mail.bcc.length).to eq User.admins.length
    expect(mail.bcc).to include User.admins.first.email
    expect(mail.subject.downcase).to match 'awaiting approval'
    # checks that there is both email and plain text, and they both have the right content
    expect(mail.body.parts.length).to eq 2
    mail.body.parts.each do |part|
      expect(part.to_s).to match event_url(event)
    end
  end

  it "sends correct emails when an event is approved" do
    coordinator = create :coordinator
    event = create :event, coordinator: coordinator
    mail = EventMailer.approve(event)
    expect(mail.to).to eq [coordinator.email]
    expect(mail.subject.downcase).to match 'approved'
    # checks that there is both email and plain text, and they both have the right content
    expect(mail.body.parts.length).to eq 2
    mail.body.parts.each do |part|
      expect(part.to_s).to match event_url(event)
    end
  end

end