require 'rails_helper'

RSpec.describe CongressService do
  let(:service) { described_class.new }

  it "inherits from QaSelectService" do
    expect(described_class).to be < QaSelectService
  end

  describe "#initialize" do
    it "initializes with congress authority" do
      expect(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('congress')
      described_class.new
    end

    it "ignores passed authority name and uses congress" do
      expect(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('congress')
      described_class.new('different_authority')
    end
  end

  describe "#select_active_options" do
    it "returns recent congress sessions" do
      expect(service.select_active_options).to include(
        ["116th (2019-2021)", "116th (2019-2021)"],
        ["117th (2021-2023)", "117th (2021-2023)"],
        ["118th (2023-2025)", "118th (2023-2025)"]
      )
    end

    it "includes historical congress sessions" do
      expect(service.select_active_options).to include(
        ["1st (1789-1791)", "1st (1789-1791)"],
        ["2nd (1791-1793)", "2nd (1791-1793)"]
      )
    end

    it "formats options as label-value pairs" do
      options = service.select_active_options
      options.each do |option|
        expect(option).to be_an(Array)
        expect(option.length).to eq(2)
        expect(option.first).to eq(option.last) # Label matches value
        expect(option.first).to match(/\d+(?:st|nd|rd|th) \(\d{4}-\d{4}\)/) # Matches format like "1st (1789-1791)" or "116th (2019-2021)"
      end
    end
  end
end