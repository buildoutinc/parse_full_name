# frozen_string_literal: true

RSpec.describe ParseFullName::Configuration do
  subject(:configuration) { described_class.new }

  it "loads conjunctions" do
    expect(configuration.conjunctions).not_to be_empty
  end

  it "loads words that should have their case forced" do
    expect(configuration.force_case_words).not_to be_empty
  end

  it "loads the prefix short list" do
    expect(configuration.prefixes).not_to be_empty
  end

  it "loads the suffix short list" do
    expect(configuration.suffixes).not_to be_empty
  end

  it "loads the title short list" do
    expect(configuration.titles).not_to be_empty
  end

  it "loads the prefix long list" do
    expect(configuration.prefixes(:long)).not_to be_empty
  end

  it "loads the suffix long list" do
    expect(configuration.suffixes(:long)).not_to be_empty
  end

  it "loads the title long list" do
    expect(configuration.titles(:long)).not_to be_empty
  end
end
