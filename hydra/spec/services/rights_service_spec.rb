require 'rails_helper'

RSpec.describe RightsService do
  let(:service) { described_class.new }

  it "inherits from QaSelectService" do
    expect(described_class).to be < QaSelectService
  end

  describe "#initialize" do
    it "initializes with rights authority" do
      expect(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('rights')
      described_class.new
    end

    it "ignores passed authority name and uses rights" do
      expect(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('rights')
      described_class.new('different_authority')
    end
  end

  describe "#select_active_options" do
    it "returns active terms" do
      expect(service.select_active_options).to include(
        ["In Copyright", "http://rightsstatements.org/vocab/InC/1.0/"],
        ["No Known Copyright", "http://rightsstatements.org/vocab/NKC/1.0/"]
      )
    end

    it "returns array of label and uri pairs" do
      options = service.select_active_options
      options.each do |option|
        expect(option).to be_an(Array)
        expect(option.length).to eq(2)
        expect(option.first).to be_a(String)  # label
        expect(option.last).to match(/^http/) # uri
      end
    end
  end
end