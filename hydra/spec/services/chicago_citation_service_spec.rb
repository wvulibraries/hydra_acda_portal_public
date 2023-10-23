require 'rails_helper'

RSpec.describe ChicagoCitationService do
  subject(:service) { described_class.new }

  describe '#format' do
    let(:doc) { SolrDocument.new(attributes) }

    context 'when all fields are present' do
      let(:access_date) { Date.today.strftime("%B %d, %Y") }
      let(:url) {"https://www.wvu.edu/"}
      let(:attributes) do
        {
          'creator_tesim' => ['Creator'],
          'title_tesim' => ['Title'],
          'date_tesim' => ['Date'],
          'physical_location_tesim' => ['Physical Location'],
          'contributing_institution_tesim' => ['Contributing Institution'] 
        }
      end

      xit 'returns a formatted citation' do
        expect(service.format(doc)).to eq(
          "Creator. <i>Title</i>. Date. Physical Location. Contributing Institution. http://example.com (accessed #{access_date})."
        )
      end 
    end

    context 'when url is not present' do
      let(:attributes) do
        {
          'creator_tesim' => ['Creator'],
          'title_tesim' => ['Title'],
          'date_tesim' => ['Date'],
          'physical_location_tesim' => ['Physical Location'],
          'contributing_institution_tesim' => ['Contributing Institution'] 
        }
      end

      it 'returns a formatted citation' do
        expect(service.format(doc)).to eq(
          "Creator. <i>Title</i>. Date. Physical Location. Contributing Institution."
        )
      end 
    end
  end

end