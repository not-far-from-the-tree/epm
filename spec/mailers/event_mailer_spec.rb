require "spec_helper"

describe EventMailer do

  before :each do
    @event = create :participatable_event
  end

  describe "attend" do

    it "sends the right content to the right person" do
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

  end

  describe "coordinator_assigned" do

    it "sends the right content to the right person" do
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

  end

end
