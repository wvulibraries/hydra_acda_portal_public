require 'rails_helper'

RSpec.feature "Audio player", type: :feature do
  before do
    # Blacklight's sidebar MoreLikeThisComponent calls document.more_like_this,
    # which requires a real Solr response. Stub it to return empty on all documents.
    allow_any_instance_of(SolrDocument).to receive(:more_like_this).and_return([])

    allow_any_instance_of(Acda).to receive(:update_index)
    allow_any_instance_of(Acda).to receive(:save)
    allow_any_instance_of(Acda).to receive(:save!)
    allow_any_instance_of(Acda).to receive(:persisted?).and_return(true)
  end

  scenario "shows audio player with correct mp3 source" do
    unique_id = "audio-test-#{SecureRandom.uuid}"
    acda = FactoryBot.create(:acda,
      dc_type: 'Sound',
      available_by: 'https://dolecollections.ku.edu/files/original/57/c031_007/c031_007.mp3',
      identifier: unique_id,
      title: 'Senator Bob Dole on Israel',
      preview: '/images/test-thumbnail.jpg'
    )
    allow_any_instance_of(Acda).to receive(:id).and_return(acda.id)
    allow_any_instance_of(Acda).to receive(:to_param).and_return(acda.id)

    solr_doc = SolrDocument.new(
      'id' => acda.id,
      'dc_type_tesim' => [acda.dc_type],
      'available_by_tesim' => [acda.available_by],
      'title_tesim' => [acda.title],
      'preview_tesim' => [acda.preview]
    )
    fake_search_service = double('search_service').as_null_object
    allow(fake_search_service).to receive(:fetch).and_return([nil, solr_doc])
    allow_any_instance_of(CatalogController).to receive(:search_service).and_return(fake_search_service)

    visit solr_document_path(acda.id)

    expect(page).to have_selector('audio[controls]')
    expect(page).to have_selector("audio[src='https://dolecollections.ku.edu/files/original/57/c031_007/c031_007.mp3']")
    expect(page).to have_content('Senator Bob Dole on Israel')
  end

  scenario "shows fallback player if no mp3 source" do
    unique_id = "audio-fallback-#{SecureRandom.uuid}"
    acda = FactoryBot.create(:acda,
      dc_type: 'Sound',
      available_by: nil,
      identifier: unique_id,
      title: 'Fallback Audio Test',
      preview: '/images/test-thumbnail.jpg'
    )
    allow_any_instance_of(Acda).to receive(:id).and_return(acda.id)
    allow_any_instance_of(Acda).to receive(:to_param).and_return(acda.id)

    solr_doc = SolrDocument.new(
      'id' => acda.id,
      'dc_type_tesim' => [acda.dc_type],
      'available_by_tesim' => [acda.available_by],
      'title_tesim' => [acda.title],
      'preview_tesim' => [acda.preview]
    )
    fake_search_service = double('search_service').as_null_object
    allow(fake_search_service).to receive(:fetch).and_return([nil, solr_doc])
    allow_any_instance_of(CatalogController).to receive(:search_service).and_return(fake_search_service)

    visit solr_document_path(acda.id)

    expect(page).to have_selector('audio[controls]')
    expect(page).to have_selector("audio[src='/audio/#{acda.id}']")
    expect(page).to have_content('Fallback Audio Test')
  end
end
