# frozen_string_literal: true

RSpec.describe ParseFullName::Name do
  subject(:name) { described_class.new }

  it "has all blank names by default" do
    expect(name.first_name).to be_empty
    expect(name.middle_name).to be_empty
    expect(name.last_name).to be_empty
    expect(name.title).to be_empty
    expect(name.suffix).to be_empty
    expect(name.nickname).to be_empty
  end

  it "can be initialized with name components" do
    data = {
      title: "Mr.",
      first_name: "James",
      middle_name: "S.A.",
      last_name: "Corey",
      suffix: "I",
      nickname: "Jim"
    }
    name = described_class.new(data)

    data.each { |k, v| expect(name.send(k)).to eq(v) }
  end

  describe "#transform" do
    it "transforms the name using the provided block" do
      name = described_class.new(
        first_name: "Pete",
        last_name: "Mitchell",
        nickname: "Maverick"
      )
      new_name = name.transform do |attribute, value|
        attribute == :nickname ? value : value.upcase
      end

      expect(new_name.first_name).to eq("PETE")
      expect(new_name.last_name).to eq("MITCHELL")
      expect(new_name.nickname).to eq("Maverick")
    end

    it "does not alter the original object" do
      name = described_class.new(
        first_name: "Pete",
        last_name: "Mitchell",
        nickname: "Maverick"
      )

      expect {
        name.transform { |_attribute, value| value.upcase }
      }.not_to change { [name.first_name, name.last_name, name.nickname] }
    end
  end
end
