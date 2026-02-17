require 'rails_helper'

RSpec.describe 'Audio player view', type: :view do
  include Blacklight::CatalogHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  let(:audio_url) { 'https://dolecollections.ku.edu/files/original/57/c031_007/c031_007.mp3' }
  let(:identifier) { 'c031_007' }
  let(:document) do
    OpenStruct.new(
      id: identifier,
      available_by_tesim: [audio_url],
      dc_type_tesim: ['Sound'],
      itemtype: 'http://schema.org/AudioObject'
    )
  end

  before do
    # Set up Blacklight configuration
    allow(view).to receive(:render_document_partials).and_return('')
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
    document_without_audio = OpenStruct.new(
      id: identifier,
      dc_type_tesim: ['Sound'],
      itemtype: 'http://schema.org/AudioObject'
    )
    assign(:document, document_without_audio)
    render template: 'catalog/_audio', locals: { document: document_without_audio }
    expect(rendered).to include("/audio/#{identifier}")
  end
end
