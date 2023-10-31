require 'rails_helper'

RSpec.describe Acda, type: :model do
  let(:acda) { Acda.new }

  describe '#assign_id' do
    it 'returns a cleaned identifier for a uri with special characters' do
      acda.identifier = 'http://www.example.com:8080/path/to/resource.html?id=123&name=test_name#section_1?extra=10%25+off'
      expect(acda.assign_id).to eq('path_to_resourcehtml_id_123_name_test_name_section_1_extra_10_25_off')
    end

    it 'returns a cleaned identifier for .mp3' do
      acda.identifier = 'c016_k001_a.mp3'
      expect(acda.assign_id).to eq('c016_k001_amp3')
    end
  end
end
