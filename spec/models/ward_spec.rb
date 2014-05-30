require 'spec_helper'

describe Ward do

  it "uses settings to determine which are active" do
    w1 = create :ward
    w2 = create :ward
    w3 = create :ward
    expect(w1.active?).to be_false
    expect(w2.active?).to be_false
    expect(w3.active?).to be_false
    setting = Configurable.find_or_initialize_by name: 'active_wards'
    setting.update value: "#{w1.id}"
    expect(w1.active?).to be_true
    expect(w2.active?).to be_false
    expect(w3.active?).to be_false
    setting.update value: "#{w2.id}, #{w3.id}"
    expect(w1.active?).to be_false
    expect(w2.active?).to be_true
    expect(w3.active?).to be_true
  end

end