require 'rails_helper'

RSpec.describe ImportLibrary do
  let(:acda_double) { class_double('Acda').as_stubbed_const }
  let(:file_obj) do
    double('FileObj', mime_type: nil, content: nil, original_name: nil, save: true).tap do |obj|
      allow(obj).to receive(:mime_type=)
      allow(obj).to receive(:content=)
      allow(obj).to receive(:original_name=)
      allow(obj).to receive(:save)
    end
  end
  let(:obj) do
    {
      image_path: '/tmp/image.jpg',
      thumb_path: '/tmp/thumb.jpg',
      audio_path: '/tmp/audio.mp3',
      video_path: '/tmp/video.mp4',
      video_image_path: '/tmp/video_image.jpg',
      video_thumb_path: '/tmp/video_thumb.jpg',
      pdf_path: '/tmp/file.pdf',
      pdf_image_path: '/tmp/pdf_image.jpg',
      pdf_thumb_path: '/tmp/pdf_thumb.jpg',
      other: 'value'
    }
  end

  describe '.create_new_record' do
    it 'calls Acda.create with filtered attributes' do
      expect(acda_double).to receive(:create).with(hash_excluding(:image_path, :thumb_path, :audio_path, :video_path, :video_image_path, :video_thumb_path, :pdf_path, :pdf_image_path, :pdf_thumb_path))
      described_class.create_new_record(obj)
    end
  end

  describe '.set_file' do
    it 'sets file attributes if file exists' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:open).and_return('file_content')
      expect(file_obj).to receive(:mime_type=).with('image/jpg')
      expect(file_obj).to receive(:content=).with('file_content')
      expect(file_obj).to receive(:original_name=).with('/tmp/image.jpg')
      described_class.set_file(file_obj, 'image/jpg', '/tmp/image.jpg')
    end

    it 'does nothing if file does not exist' do
      allow(File).to receive(:exist?).and_return(false)
      expect(described_class.set_file(file_obj, 'image/jpg', '/tmp/image.jpg')).to be_nil
    end
  end

  describe '.import_record' do
    let(:new_record) do
      double('Acda', files: double('Files', build: true), save: true,
        build_image_file: file_obj, build_thumbnail_file: file_obj, build_pdf_file: file_obj,
        build_audio_file: file_obj, build_video_file: file_obj)
    end

    it 'creates and saves a new record with files' do
      allow(described_class).to receive(:create_new_record).and_return(new_record)
      allow(File).to receive(:exist?).and_return(true)
      allow(described_class).to receive(:set_file)
      expect(new_record).to receive(:save)
      described_class.import_record('id', obj)
    end

    it 'retries on RuntimeError and eradicates if not tombstone error' do
      allow(described_class).to receive(:create_new_record).and_raise(RuntimeError.new('other error'))
      allow(Acda).to receive(:eradicate).and_return('ok')
      expect(Acda).to receive(:eradicate).at_least(:once)
      described_class.import_record('id', obj)
    end

    it 'retries and deletes tombstone if error message matches' do
      error = RuntimeError.new("Can't call create on an existing resource (uri)")
      call_count = 0
      allow(described_class).to receive(:create_new_record) do
        call_count += 1
        raise error if call_count < 2
        new_record
      end
      allow(Acda).to receive(:create).and_return(new_record) # Prevent real Acda.create call
      allow(Kernel).to receive(:system)
      expect(described_class).to receive(:create_new_record).at_least(:once).and_call_original
      described_class.import_record('id', obj)
    end

    it 'executes curl deletes and outputs for tombstone error' do
      error = RuntimeError.new("Can't call create on an existing resource (http://example.org/resource/123)")
      call_count = 0
      allow(described_class).to receive(:create_new_record) do
        call_count += 1
        raise error if call_count < 2
        double('Acda', files: double('Files', build: true), save: true,
          build_image_file: file_obj, build_thumbnail_file: file_obj, build_pdf_file: file_obj,
          build_audio_file: file_obj, build_video_file: file_obj)
      end
      allow(File).to receive(:exist?).and_return(false)
      # Stub shelling out
      expect(described_class).to receive(:`).with(' curl -X DELETE http://example.org/resource/123 ').and_return('')
      expect(described_class).to receive(:`).with(' curl -X DELETE http://example.org/resource/123/fcr:tombstone ').and_return('')
      # Capture puts output
      expect { described_class.import_record('id', obj) }
        .to output(/deleting record and tombstone from fedora and retrying create/).to_stdout
    end

    it 'retries multiple times on error' do
      call_count = 0
      allow(ImportLibrary).to receive(:create_new_record) do
        call_count += 1
        raise RuntimeError, 'fail' if call_count < 3
        double('Acda', files: double('Files', build: true), save: true,
          build_image_file: file_obj, build_thumbnail_file: file_obj, build_pdf_file: file_obj,
          build_audio_file: file_obj, build_video_file: file_obj)
      end
      allow(Acda).to receive(:eradicate).and_return('ok')
      allow(File).to receive(:exist?).and_return(false)
      expect { described_class.import_record('id', obj) }.not_to raise_error
    end
    it 'does not call set_file if no files exist' do
      allow(ImportLibrary).to receive(:create_new_record).and_return(double('Acda', files: double('Files', build: true), save: true,
        build_image_file: file_obj, build_thumbnail_file: file_obj, build_pdf_file: file_obj,
        build_audio_file: file_obj, build_video_file: file_obj))
      allow(File).to receive(:exist?).and_return(false)
      expect(ImportLibrary).not_to receive(:set_file)
      described_class.import_record('id', obj)
    end
  end

  describe '.update_file' do
    it 'updates file attributes and saves' do
      allow(File).to receive(:open).and_return('file_content')
      expect(file_obj).to receive(:mime_type=).with('image/jpg')
      expect(file_obj).to receive(:content=).with('file_content')
      expect(file_obj).to receive(:original_name=).with('/tmp/image.jpg')
      expect(file_obj).to receive(:save)
      described_class.update_file(file_obj, 'image/jpg', '/tmp/image.jpg')
    end
  end

  describe '.update_record' do
    let(:updated_record) do
      double('Acda', update: true, save: true,
        image_file: nil, thumbnail_file: nil, pdf_file: nil, audio_file: nil, video_file: nil,
        build_image_file: file_obj, build_thumbnail_file: file_obj, build_pdf_file: file_obj,
        build_audio_file: file_obj, build_video_file: file_obj)
    end
    it 'updates record and sets files' do
      allow(File).to receive(:exist?).and_return(true)
      allow(described_class).to receive(:set_file)
      allow(described_class).to receive(:update_file)
      expect(updated_record).to receive(:update)
      expect(updated_record).to receive(:save)
      described_class.update_record(updated_record, obj)
    end
    it 'calls set_file if file is nil and exists' do
      allow(File).to receive(:exist?).and_return(true)
      allow(described_class).to receive(:set_file)
      allow(described_class).to receive(:update_file)
      expect(described_class).to receive(:set_file).at_least(:once)
      described_class.update_record(updated_record, obj)
    end
    it 'calls update_file if file is not nil and exists' do
      record = double('Acda', update: true, save: true,
        image_file: file_obj, thumbnail_file: file_obj, pdf_file: file_obj, audio_file: file_obj, video_file: file_obj,
        build_image_file: file_obj, build_thumbnail_file: file_obj, build_pdf_file: file_obj,
        build_audio_file: file_obj, build_video_file: file_obj)
      allow(File).to receive(:exist?).and_return(true)
      allow(described_class).to receive(:set_file)
      allow(described_class).to receive(:update_file)
      expect(described_class).to receive(:update_file).at_least(:once)
      described_class.update_record(record, obj)
    end
    it 'does not call set_file or update_file if file does not exist' do
      allow(File).to receive(:exist?).and_return(false)
      allow(described_class).to receive(:set_file)
      allow(described_class).to receive(:update_file)
      expect(described_class).not_to receive(:set_file)
      expect(described_class).not_to receive(:update_file)
      described_class.update_record(updated_record, obj)
    end
  end

  describe '.find_file_name' do
    it 'returns idno file if exists' do
      allow(File).to receive(:exist?).with('/tmp/path/123.jpg').and_return(true)
      expect(described_class.find_file_name('/tmp/path', '123', 'abc', 'jpg')).to eq('/tmp/path/123.jpg')
    end
    it 'returns identifier file if idno file does not exist' do
      allow(File).to receive(:exist?).with('/tmp/path/123.jpg').and_return(false)
      expect(described_class.find_file_name('/tmp/path', '123', 'abc', 'jpg')).to eq('/tmp/path/abc.jpg')
    end
  end

  describe '.modify_record' do
    let(:record) do
      {
        'identifier' => 'id',
        'contributing_institution' => 'inst',
        'title' => 'title',
        'date' => 'date',
        'edtf' => 'edtf',
        'creator' => 'creator',
        'rights' => 'rights',
        'language' => 'en',
        'coverage_congress' => 'congress',
        'collection' => 'coll',
        'collection_finding_aid' => 'aid',
        'record_type' => 'type',
        'subject_policy' => 'policy',
        'subject_topical' => 'topic',
        'subject_names' => 'names',
        'coverage_spatial' => 'spatial',
        'extent' => 'extent',
        'publisher' => 'pub',
        'description' => 'desc',
        'dc_type' => 'dc',
        'idno' => 'idno'
      }
    end
    before do
      stub_const('HydraFormatting', Class.new do
        def self.valid_string(val); val; end
        def self.split_subjects(val); [val]; end
        def self.remove_special_chars(val); val; end
      end)
      allow(described_class).to receive(:find_file_name).and_return('file_path')
    end
    it 'returns a hash with expected keys' do
      result = described_class.modify_record('/tmp/export', record)
      expect(result).to include(:id, :contributing_institution, :title, :date, :edtf, :creator, :rights, :language, :congress, :collection_title, :collection_finding_aid, :identifier, :record_type, :policy_area, :topic, :names, :location_represented, :extent, :publisher, :description, :dc_type, :project, :read_groups, :image_path, :thumb_path, :audio_path, :video_path, :video_image_path, :video_thumb_path, :pdf_path, :pdf_image_path, :pdf_thumb_path)
    end
  end

  describe '.prompt' do
    it 'returns stripped, downcased input' do
      allow(described_class).to receive(:gets).and_return(" YES ")
      expect(described_class.prompt).to eq('yes')
    end
    it 'returns "no" for empty input' do
      allow(described_class).to receive(:gets).and_return("")
      expect(described_class.prompt).to eq('no')
    end
    it 'returns "no" for whitespace input' do
      allow(described_class).to receive(:gets).and_return("   ")
      expect(described_class.prompt).to eq('no')
    end
  end
end
