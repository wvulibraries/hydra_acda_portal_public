require 'rails_helper'

RSpec.describe ChicagoCitationService do
  subject(:service) { described_class }

  describe '#format' do
    let(:doc) { SolrDocument.new(attributes) }
    let(:url) {"https://www.wvu.edu/catalog/1234"}
    let(:access_date) { Date.today.strftime("%B %d, %Y") }

    context 'when all fields are present' do
      let(:attributes) do
        {
          'title_tesim' => ['Title'],
          'date_tesim' => ['Date'],
          'physical_location_tesim' => ['Physical Location'],
          'contributing_institution_tesim' => ['Contributing Institution']
        }
      end

      it 'returns a formatted citation' do
        expect(service.format(document: doc, original_url: url)).to eq(
          "<i>Title</i>, Date, Physical Location, Contributing Institution. https://www.wvu.edu/catalog/1234 (accessed #{access_date})."
        )
      end
    end

    context 'when url is not present' do
      let(:attributes) do
        {
          'title_tesim' => ['Title'],
          'date_tesim' => ['Date'],
          'physical_location_tesim' => ['Physical Location'],
          'contributing_institution_tesim' => ['Contributing Institution']
        }
      end

      it 'returns a formatted citation' do
        expect(service.format(document: doc, original_url: url)).to eq(
          "<i>Title</i>, Date, Physical Location, Contributing Institution. https://www.wvu.edu/catalog/1234 (accessed #{access_date})."
        )
      end
    end
  end
end
