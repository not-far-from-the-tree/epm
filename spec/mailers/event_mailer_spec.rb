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

  it "sends correct emails when an event is cancelled" do
    mail = EventMailer.cancel(@event, @event.users)
    expect(mail.to).to be_nil
    expect(mail.bcc.length).to eq @event.users.length
    expect(mail.bcc.first).to match @event.users.first.email
    expect(mail.subject).to match 'cancelled'
    # checks that there is both email and plain text, and they both have the right content
    expect(mail.body.parts.length).to eq 2
    mail.body.parts.each do |part|
      expect(part.to_s).to match 'cancelled'
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
    end
  end


end
