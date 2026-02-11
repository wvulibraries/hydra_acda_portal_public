require 'rails_helper'

RSpec.describe 'Audio player view', type: :view do
  let(:audio_url) { 'https://dolecollections.ku.edu/files/original/57/c031_007/c031_007.mp3' }
  let(:identifier) { 'c031_007' }
  let(:document) do
    {
      id: identifier,
      available_by_tesim: [audio_url],
      dc_type_ssi: 'Sound'
    }
  end

  before do
    # Stub blacklight_config to prevent errors in partial
    allow(view).to receive(:blacklight_config).and_return(OpenStruct.new(view_config: OpenStruct.new(show: OpenStruct.new(partials: []))))
    allow(view).to receive(:render_document_class).and_return('')
  end

  it 'renders the audio player with the correct mp3 source' do
    assign(:document, document)
    render template: 'catalog/_audio', locals: { document: document }
    expect(rendered).to include(audio_url)
    expect(rendered).to include('<audio')
    expect(rendered).to include('controls')
  end

  it 'renders fallback player if no audio_url' do
    document.delete(:available_by_tesim)
    assign(:document, document)
    render template: 'catalog/_audio', locals: { document: document }
    expect(rendered).to include("/audio/#{identifier}")
  end
end
