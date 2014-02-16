require 'spec_helper'

describe Event do

  it "has a start" do
    expect(create(:event)).to respond_to :start
  end

  it "has a finish" do
    expect(create(:event)).to respond_to :finish
  end

  it "is invalid without a start" do
    expect(build(:event, start: nil)).not_to be_valid
  end

  it "is invalid without a finish" do
    expect(build(:event, finish: nil)).not_to be_valid
  end

end