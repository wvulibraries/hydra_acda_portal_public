require 'rails_helper'


RSpec.feature "Audio player", type: :feature do
  scenario "shows audio player with correct mp3 source" do
    unique_id = "audio-test-#{SecureRandom.uuid}"
    acda = FactoryBot.create(:acda,
      dc_type: 'Sound',
      available_by: 'https://dolecollections.ku.edu/files/original/57/c031_007/c031_007.mp3',
      identifier: unique_id,
      title: 'Senator Bob Dole on Israel',
      preview: '/images/test-thumbnail.jpg'
    )

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
    visit solr_document_path(acda.id)
    expect(page).to have_selector('audio[controls]')
    expect(page).to have_selector("audio[src='/audio/#{unique_id}']")
    expect(page).to have_content('Fallback Audio Test')
  end
end
