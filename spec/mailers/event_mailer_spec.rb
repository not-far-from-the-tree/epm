require "spec_helper"

describe EventMailer do

  describe "attend" do

    before :each do
      @user = create :participant
      @event = create :participatable_event
    end

    it "sends" do
      mail = EventMailer.attend(@event, @user)
      expect(mail.to.length).to eq 1
      expect(mail.to.first).to match @user.email
      expect(mail.subject).to eq 'You have joined an event'
      # checks that there is both email and plain text, and they both have the right content
      expect(mail.body.parts.length).to eq 2
      mail.body.parts.each do |part|
        expect(part.to_s).to match event_url(@event)
      end
    end

  end

end
