require 'spec_helper'

describe EventUser do

  context "validity" do

    it "is invalid without an event" do
      expect(build :event_user, event: nil).not_to be_valid
    end

    it "is invalid without a user" do
      expect(build :event_user, user: nil).not_to be_valid
    end

    it "is invalid without a status" do
      expect(build :event_user, status: nil).not_to be_valid
    end

    it "does not allow attending the same event more than once" do
      eu1 = create :event_user
      expect(build :event_user, user: eu1.user, event: eu1.event).not_to be_valid
    end

    it "can returns multiple status values" do
      expect(EventUser.statuses_array :invited).to eq [EventUser.statuses[:invited]]
      expect(EventUser.statuses_array :attending, :waitlisted).to eq [EventUser.statuses[:attending], EventUser.statuses[:waitlisted]]
      expect(EventUser.statuses_array :requested, :attended, :no_show).to eq [EventUser.statuses[:requested], EventUser.statuses[:attended], EventUser.statuses[:no_show]]
    end

  end

  context "cancelling" do

    it "adds people from a waitlist" do
      event = create :participatable_event, max: 1
      will_cancel = create :event_user, event: event, user: create(:participant), status: :attending
      will_attend = create :event_user, event: event, user: create(:participant), status: :waitlisted
      will_cancel.unattend
      expect(will_attend.reload.attending?).to be_true
    end

    it "does not add people from a waitlist when withdrawing from waitlist rather than cancelling" do
      event = create :participatable_event, max: 1
      attending = create :event_user, event: event, user: create(:participant), status: :attending
      waitlisted = create :event_user, event: event, user: create(:participant), status: :waitlisted
      will_withdraw = create :event_user, event: event, user: create(:participant), status: :waitlisted
      will_withdraw.unattend
      expect(event.participants.reload).to eq [attending.user]
    end

  end

end