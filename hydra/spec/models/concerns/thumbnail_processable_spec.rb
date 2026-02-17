require 'rails_helper'

RSpec.describe ThumbnailProcessable do
  # Use the Acda model which includes ThumbnailProcessable
  let(:acda) do
    acda = FactoryBot.build(:acda, dc_type: 'Image', queued_job: nil)
    allow(acda).to receive(:save).and_return(true)
    allow(acda).to receive(:save!).and_return(true)
    allow(acda).to receive(:update_index)
    acda
  end

  describe '#should_process_thumbnail?' do
    it 'returns false when dc_type is nil' do
      acda.dc_type = nil
      expect(acda.should_process_thumbnail?).to be false
    end

    it 'returns false when dc_type is Sound' do
      acda.dc_type = 'Sound'
      expect(acda.should_process_thumbnail?).to be false
    end

    it 'returns false when dc_type is Moving' do
      acda.dc_type = 'Moving'
      expect(acda.should_process_thumbnail?).to be false
    end

    it 'returns false when queued_job is true' do
      acda.dc_type = 'Image'
      acda.queued_job = 'true'
      expect(acda.should_process_thumbnail?).to be false
    end

    it 'returns false when no relevant changes occurred' do
      allow(acda).to receive(:saved_change_to_preview?).and_return(false)
      allow(acda).to receive(:saved_change_to_available_by?).and_return(false)
      allow(acda).to receive(:saved_change_to_available_at?).and_return(false)
      expect(acda.should_process_thumbnail?).to be false
    end

    it 'returns true when preview changed and thumbnail/image files unchanged' do
      allow(acda).to receive(:saved_change_to_preview?).and_return(true)
      allow(acda).to receive(:saved_change_to_thumbnail_file?).and_return(false)
      allow(acda).to receive(:saved_change_to_image_file?).and_return(false)
      expect(acda.should_process_thumbnail?).to be true
    end

    it 'returns false when preview changed but thumbnail_file also changed' do
      allow(acda).to receive(:saved_change_to_preview?).and_return(true)
      allow(acda).to receive(:saved_change_to_thumbnail_file?).and_return(true)
      allow(acda).to receive(:saved_change_to_image_file?).and_return(false)
      expect(acda.should_process_thumbnail?).to be false
    end
  end

  describe '#needs_thumbnail_download?' do
    it 'returns false when preview is blank' do
      acda.preview = nil
      expect(acda.needs_thumbnail_download?).to be false
    end

    it 'returns true when preview is present, url is active, and image_file is blank' do
      acda.preview = 'https://example.com/image.jpg'
      allow(acda).to receive(:is_active_url?).with(acda.preview).and_return(true)
      allow(acda).to receive(:image_file).and_return(double(blank?: true))
      allow(acda).to receive(:saved_change_to_preview?).and_return(false)
      expect(acda.needs_thumbnail_download?).to be true
    end

    it 'returns false when preview url is not active' do
      acda.preview = 'https://example.com/image.jpg'
      allow(acda).to receive(:is_active_url?).with(acda.preview).and_return(false)
      expect(acda.needs_thumbnail_download?).to be false
    end
  end

  describe '#update_thumbnail_and_image' do
    it 'does nothing when queued_job is true' do
      acda.queued_job = 'true'
      expect(DownloadAndSetThumbsJob).not_to receive(:perform_later)
      acda.update_thumbnail_and_image
    end

    it 'queues DownloadAndSetThumbsJob when needs_thumbnail_download? is true' do
      allow(acda).to receive(:needs_thumbnail_download?).and_return(true)
      allow(acda).to receive(:id).and_return('test-uuid')
      allow(acda).to receive(:save).and_return(true)
      expect(DownloadAndSetThumbsJob).to receive(:perform_later).with('test-uuid')
      acda.update_thumbnail_and_image
    end

    it 'sets queued_job to true before enqueuing' do
      allow(acda).to receive(:needs_thumbnail_download?).and_return(true)
      allow(acda).to receive(:id).and_return('test-uuid')
      allow(DownloadAndSetThumbsJob).to receive(:perform_later)
      acda.update_thumbnail_and_image
      expect(acda.queued_job).to eq('true')
    end

    it 'does not queue a job when needs_thumbnail_download? is false' do
      allow(acda).to receive(:needs_thumbnail_download?).and_return(false)
      expect(DownloadAndSetThumbsJob).not_to receive(:perform_later)
      acda.update_thumbnail_and_image
    end
  end

  describe '#saved_change_to_thumbnail_file?' do
    it 'returns true when previous_changes includes thumbnail_file' do
      allow(acda).to receive(:previous_changes).and_return({ 'thumbnail_file' => ['old', 'new'] })
      expect(acda.saved_change_to_thumbnail_file?).to be true
    end

    it 'returns false when previous_changes does not include thumbnail_file' do
      allow(acda).to receive(:previous_changes).and_return({})
      expect(acda.saved_change_to_thumbnail_file?).to be false
    end
  end

  describe '#saved_change_to_image_file?' do
    it 'returns true when previous_changes includes image_file' do
      allow(acda).to receive(:previous_changes).and_return({ 'image_file' => ['old', 'new'] })
      expect(acda.saved_change_to_image_file?).to be true
    end

    it 'returns false when previous_changes does not include image_file' do
      allow(acda).to receive(:previous_changes).and_return({})
      expect(acda.saved_change_to_image_file?).to be false
    end
  end
end
