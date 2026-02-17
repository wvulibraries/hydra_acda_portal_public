# Test helper to stub Fedora/ActiveFedora network calls for feature specs
RSpec.configure do |config|
  config.before(:each, type: :feature) do
    allow_any_instance_of(ActiveFedora::Base).to receive(:save).and_return(true)
    allow_any_instance_of(ActiveFedora::Base).to receive(:save!).and_return(true)
    allow_any_instance_of(ActiveFedora::Base).to receive(:update).and_return(true)
    allow_any_instance_of(ActiveFedora::Base).to receive(:update!).and_return(true)
    allow_any_instance_of(ActiveFedora::Base).to receive(:destroy).and_return(true)
    allow_any_instance_of(ActiveFedora::Base).to receive(:destroy!).and_return(true)
  end
end
