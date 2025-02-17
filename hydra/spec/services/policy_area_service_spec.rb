require 'rails_helper'

RSpec.describe PolicyAreaService do
  let(:service) { described_class.new }

  it "inherits from QaSelectService" do
    expect(described_class).to be < QaSelectService
  end

  describe "#initialize" do
    it "initializes with policy_area authority" do
      expect(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('policy_area')
      described_class.new
    end

    it "ignores passed authority name and uses policy_area" do
      expect(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('policy_area')
      described_class.new('different_authority')
    end
  end

  describe "#select_active_options" do
    it "returns active policy areas" do
      expect(service.select_active_options).to include(
        ["Agriculture and Food", "Agriculture and Food"],
        ["Animals", "Animals"],
        ["Transportation and Public Works", "Transportation and Public Works"]
      )
    end

    it "formats options as label-value pairs" do
      options = service.select_active_options
      options.each do |option|
        expect(option).to be_an(Array)
        expect(option.length).to eq(2)
        expect(option.first).to be_a(String)
        expect(option.last).to be_a(String)
      end
    end
  end

  describe "#label" do
    it "returns proper label for a policy area id" do
      expect(service.label("Agriculture and Food")).to eq("Agriculture and Food")
    end
  end

  describe "#active?" do
    it "checks if a policy area is active" do
      policy_area = service.select_active_options.first
      expect(service.active?(policy_area.last)).to be true
    end
  end
end