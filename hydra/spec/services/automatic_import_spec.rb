require 'rails_helper'

RSpec.describe AutomaticImport do
 let(:timestamp) { Time.now.to_i.to_s }
 let(:control_file) do
   {
     'project_name' => 'test_project',
     'time_stamp' => timestamp,
     'contact_emails' => ['test@example.com']
   }
 end
 
 let(:logger) { double('Logger', info: nil, debug: nil) }
 let(:import) { described_class.new(control_file) }

 before do
   allow(File).to receive(:open).and_return(double('file'))
   allow(Logger).to receive(:new).and_return(logger)

   stub_request(:get, /solr.*/)
     .with(
       headers: {
         'Accept'=>'*/*',
         'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'Authorization'=>'Basic aHlkcmE6bTBOaWY3ck5wM1pwa2lLTjUyTkE=',
         'User-Agent'=>'Faraday v2.12.2'
       }
     )
     .to_return(status: 200, body: "", headers: {})
 end

 describe '#initialize' do
   it 'sets up logger and paths' do
     expect(Logger).to receive(:new)
     described_class.new(control_file)
   end
 end

 describe '#parse_data' do
   let(:json_data) do
     [
       { 'identifier' => 'test.123', 'title' => 'Test Record' },
       { 'identifier' => 'test.456', 'title' => 'EXCLUDE This Record' }
     ].to_json
   end

   before do
     allow(ImportLibrary).to receive(:modify_record).and_return({})
     allow(ImportLibrary).to receive(:import_record).and_return(true)
     allow(ImportLibrary).to receive(:update_record).and_return(true)
     allow(Acda).to receive(:where).and_return([])
   end

   it 'skips records with EXCLUDE in title' do
     expect(ImportLibrary).not_to receive(:modify_record)
       .with(anything, hash_including('title' => 'EXCLUDE This Record'))
     import.parse_data(json_data)
   end

   it 'processes valid records' do
     expect(ImportLibrary).to receive(:modify_record)
       .with(anything, hash_including('title' => 'Test Record'))
     import.parse_data(json_data)
   end

   context 'when record exists' do
     let(:existing_record) { double('Acda') }
     
     before do
       allow(Acda).to receive(:where).and_return([existing_record])
     end

     it 'updates existing record' do
       expect(ImportLibrary).to receive(:update_record)
         .with(existing_record, anything)
       import.parse_data(json_data)
     end
   end

   context 'when record is new' do
     before do
       allow(Acda).to receive(:where).and_return([])
     end

     it 'creates new record' do
       expect(ImportLibrary).to receive(:import_record)
       import.parse_data(json_data)
     end
   end

   it 'adds error text if import_record returns false' do
     allow(ImportLibrary).to receive(:import_record).and_return(false)
     expect { import.parse_data(json_data) }.not_to raise_error
     expect(import.instance_variable_get(:@email_details)).to include('failed to create')
   end

   it 'adds error text if update_record returns false' do
     allow(Acda).to receive(:where).and_return([double('Acda')])
     allow(ImportLibrary).to receive(:update_record).and_return(false)
     expect { import.parse_data(json_data) }.not_to raise_error
     expect(import.instance_variable_get(:@email_details)).to include('failed to update')
   end

   it 'handles record with nil title' do
     data = [{ 'identifier' => 'test.789', 'title' => nil }].to_json
     expect { import.parse_data(data) }.not_to raise_error
   end

   it 'handles record with nil identifier' do
     data = [{ 'identifier' => nil, 'title' => 'Test Record' }].to_json
     expect { import.parse_data(data) }.not_to raise_error
   end

   it 'rescues RuntimeError and aborts' do
     allow(ImportLibrary).to receive(:import_record).and_raise(RuntimeError, 'fail')
     expect(import).to receive(:puts).at_least(:once)
     expect { import.parse_data(json_data) }.to raise_error(SystemExit)
   end

   it 'handles empty JSON array' do
     expect { import.parse_data([].to_json) }.not_to raise_error
   end
 end

 describe '#send_feedback' do
   context 'in production' do
     before do
       allow(Rails.env).to receive(:production?).and_return(true)
     end

     it 'sends email' do
       mailer = double('ImportMailer')
       expect(ImportMailer).to receive(:email).and_return(mailer)
       expect(mailer).to receive(:deliver_now)
       import.send_feedback
     end
   end

   context 'not in production' do
     before do
       allow(Rails.env).to receive(:production?).and_return(false)
     end

     it 'does not send email' do
       expect(ImportMailer).not_to receive(:email)
       import.send_feedback
     end
   end
 end

 describe '#run' do
   context 'when data file exists' do
     before do
       allow(Dir).to receive(:[]).and_return(['test.json'])
       allow(File).to receive(:exist?).and_return(true)
       allow(File).to receive(:read).and_return('[]')
       allow(import).to receive(:parse_data)
     end

     it 'reads and parses data file' do
       expect(import).to receive(:parse_data)
       import.run
     end
   end

   context 'when data file does not exist' do
     before do
       allow(Dir).to receive(:[]).and_return(['test.json'])
       allow(File).to receive(:exist?).and_return(false)
     end

     it 'aborts with error message' do
       expect { import.run }.to raise_error(SystemExit, "No data file found")
     end
   end

   it 'aborts if Dir[] returns empty array' do
     allow(Dir).to receive(:[]).and_return([])
     expect { import.run }.to raise_error(SystemExit, 'No data file found')
   end
 end

 describe '#write_logs' do
   let(:message) { 'Test log message' }

   it 'writes message to logger' do
     expect(logger).to receive(:debug).with(message)
     import.write_logs(message)
   end
 end
end