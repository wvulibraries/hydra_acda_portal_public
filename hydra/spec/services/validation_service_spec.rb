# spec/services/validation_service_spec.rb

require 'rails_helper'

RSpec.describe ValidationService do
  let(:valid_csv_path) { 'spec/fixtures/validation_service_fixtures/valid.csv' }
  let(:invalid_csv_path) { 'spec/fixtures/validation_service_fixtures/invalid.csv' }
  let(:qa_service) { instance_double('QaSelectService') }
  let(:authority) { instance_double('Qa::Authorities::Local::FileBasedAuthority') }

  describe '#validate' do
    context 'with valid values' do
      let(:service) { described_class.new(path: valid_csv_path) }
      before do
        # Stub LC request
        stub_request(:get, "https://id.loc.gov/search/?format=atom&q=%22Test%20Creator%22")
          .with(headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host'=>'id.loc.gov',
            'User-Agent'=>'Ruby'
          })
          .to_return(status: 200, body: <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <feed xmlns="http://www.w3.org/2005/Atom">
              <entry><title>Test Creator</title></entry>
            </feed>
          XML
          )
        
        stub_request(:get, %r{https://www\.getty\.edu/vow/TGNServlet.*})
          .to_return(
            status: 200,
            body: <<~HTML
              <html>
                <body>
                  <table>
                    <tr>
                      <td valign="bottom" colspan="2">
                        <span class="page"><a><b>Maryland</b></a> (state)</span>
                      </td>
                    </tr>
                  </table>
                </body>
              </html>
            HTML
          )

        # # Stub Local Authority
        allow(QaSelectService).to receive(:new).with('rights').and_return(qa_service)
        allow(QaSelectService).to receive(:new).with('types').and_return(qa_service)

        allow(qa_service).to receive(:authority).and_return(authority)
        allow(authority).to receive(:find).with('Public Domain').and_return({ 'active' => true })
        allow(authority).to receive(:find).with('photographs').and_return({ 'active' => true })

        # Stub ISO Language
        allow(ISO_639).to receive(:find_by_code).with('eng').and_return(['eng'])
      end

      it 'validates successfully' do
        stub_request(:get, "https://vocab.getty.edu/sparql")
          .with(query: hash_including({format: 'json'}))
          .to_return(
            status: 200,
            body: {
              results: {
                bindings: [{
                  concept: { value: 'http://vocab.getty.edu/aat/123' }
                }]
              }
            }.to_json
          )
    
        service.validate
        expect(service.results).to be_empty
      end

      it 'falls back to HTML lookup successfully when SPARQL fails' do
        stub_request(:get, "https://vocab.getty.edu/sparql")
        .with(query: hash_including({format: 'json'}))
          .to_return(
            status: 200,
              body: {
                results: {
                bindings: []
              }
              }.to_json
        )

        stub_request(:get, %r{https://www\.getty\.edu/vow/AATServlet.*})
          .to_return(
            status: 200,
            body: <<~HTML
              <html>
                <body>
                  <td valign="bottom" colspan="2">
                    <span class="page">
                      <a><b>Oil paintings</b></a>
                    </span>
                  </td>
                </body>
              </html>
            HTML
          )

        service.validate
        expect(service.results).to be_empty
      end
    end

    context 'with invalid values' do
      let(:service) { described_class.new(path: invalid_csv_path) }

      before do
        # Stub LC request - empty response
        stub_request(:get, "https://id.loc.gov/search/?format=atom&q=%22Invalid%20Creator%22")
          .with(headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host'=>'id.loc.gov',
            'User-Agent'=>'Ruby'
          })
          .to_return(status: 200, body: <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <feed xmlns="http://www.w3.org/2005/Atom"></feed>
          XML
          )

        # Return empty/invalid response for Getty AAT SPARQL
        stub_request(:get, "https://vocab.getty.edu/sparql")
          .with(query: hash_including({format: 'json'}))
            .to_return(
              status: 200,
                body: {
                  results: {
                  bindings: []
                }
                }.to_json
            )
        
        # Return empty/invalid response for Getty AAT Online Tool
        stub_request(:get, %r{https://www\.getty\.edu/vow/AATServlet.*})
          .to_return(
            status: 200,
            body: "<html><body></body></html>",
            headers: { 'Content-Type': 'text/html' }
          )

        # Return empty/invalid response for Getty TGN
        stub_request(:get, %r{https://www\.getty\.edu/vow/TGNServlet.*})
          .to_return(status: 200, body: "<html></html>")


        # Stub Local Authority - inactive
        allow(QaSelectService).to receive(:new).with('rights').and_return(qa_service)
        allow(QaSelectService).to receive(:new).with('types').and_return(qa_service)

        allow(qa_service).to receive(:authority).and_return(authority)
        allow(authority).to receive(:find).with('Invalid Rights').and_return({ 'active' => false })
        allow(authority).to receive(:find).with('invalid-type').and_return({ 'active' => false })

        # Stub ISO Language - invalid
        allow(ISO_639).to receive(:find_by_code).with('xyz').and_return(nil)
      end

      it 'reports all validation errors' do
        results = service.validate
        expect(results).to match_array([
          hash_including(
            header: "dcterms:creator",
            message: "<strong>Invalid Creator</strong> was not found in LC Linked Data Service (LCNAF)",
            row: 2
          ),
          hash_including(
            header: "dcterms:created",
            message: "<strong>not-a-date</strong> is not a valid EDTF",
            row: 2
          ),
          hash_including(
            header: "dcterms:language",
            message: "<strong>xyz</strong> is not a valid language code",
            row: 2
          ),
          hash_including(
            header: "dcterms:rights",
            message: "<strong>Invalid Rights</strong> is not valid",
            row: 2
          ),
          hash_including(
            header: "dcterms:type",
            message: "<strong>invalid-type</strong> is not valid",
            row: 2
          ),
          hash_including(
            header: "dcterms:spatial",
            message: "<strong>Invalid Place (invalid)</strong> was not found in Getty TGN",
            row: 2
          ),
          hash_including(
            header: "dcterms:source",
            message: "<strong>not-a-url</strong> is an invalid URL format",
            row: 2
          ),
          hash_including(
            header: "dcterms:http://purl.org/dc/terms/type",
            message: "<strong>wrong</strong> was not found in Getty AAT",
            row: 2
          ),
        ])
      end
    end
  end

  describe '#search_getty_aat' do
    let(:service) { described_class.new(path: valid_csv_path) }

    before do
      service.instance_variable_set(:@header, 'dcterms:http://purl.org/dc/terms/type')
      service.instance_variable_set(:@row_number, 1)
    end

    it 'succeeds with SPARQL match' do
      service.instance_variable_set(:@values, ['Oil paintings'])
      
      stub_request(:get, "https://vocab.getty.edu/sparql")
        .with(query: hash_including({format: 'json'}))
        .to_return(
          status: 200,
          body: {
            results: {
              bindings: [{
                concept: { value: 'http://vocab.getty.edu/aat/123' }
              }]
            }
          }.to_json
        )

      service.send(:search_getty_aat)
      expect(service.results).to be_empty
    end

    it 'falls back to HTML when SPARQL fails' do
      service.instance_variable_set(:@values, ['Oil paintings'])
      
      stub_request(:get, "https://vocab.getty.edu/sparql")
        .with(query: hash_including({format: 'json'}))
        .to_return(
          status: 200,
          body: {
            results: { bindings: [] }
          }.to_json
        )

      stub_request(:get, %r{https://www\.getty\.edu/vow/AATServlet.*})
        .to_return(
          status: 200,
          body: <<~HTML
            <html>
              <body>
                <td valign="bottom" colspan="2">
                  <span class="page">
                    <a><b>Oil paintings</b></a>
                  </span>
                </td>
              </body>
            </html>
          HTML
        )

      service.send(:search_getty_aat)
      expect(service.results).to be_empty
    end

    #Will fail, we don't take care of timeouts 
    it 'handles SPARQL endpoint failures' do
      service.instance_variable_set(:@values, ['Oil paintings'])
      
      stub_request(:get, "https://vocab.getty.edu/sparql")
        .with(query: hash_including({format: 'json'}))
        .to_timeout

      stub_request(:get, %r{https://www\.getty\.edu/vow/AATServlet.*})
        .to_return(
          status: 200,
          body: <<~HTML
            <html>
              <body>
                <td valign="bottom" colspan="2">
                  <span class="page">
                    <a><b>Oil paintings</b></a>
                  </span>
                </td>
              </body>
            </html>
          HTML
        )

      service.send(:search_getty_aat)
      expect(service.results).to be_empty
    end
  end

  describe '#search_getty_tgn' do
    let(:service) { described_class.new(path: valid_csv_path) }

    before do
      service.instance_variable_set(:@header, 'dcterms:spatial')
      service.instance_variable_set(:@row_number, 1)
    end

    it 'validates place with type correctly' do
      service.instance_variable_set(:@values, ['Maryland (state)'])
      
      stub_request(:get, %r{https://www\.getty\.edu/vow/TGNServlet.*})
        .to_return(
          status: 200,
          body: <<~HTML
            <html>
              <body>
                <td valign="bottom" colspan="2">
                  <span class="page"><a><b>Maryland</b></a> (state)</span>
                </td>
              </body>
            </html>
          HTML
        )

      service.send(:search_getty_tgn)
      expect(service.results).to be_empty
    end

    it 'handles malformed place values' do
      service.instance_variable_set(:@values, ['Invalid Format'])
      
      service.send(:search_getty_tgn)
      expect(service.results).to include(
        hash_including(
          header: 'dcterms:spatial',
          message: 'Invalid Format is not valid'
        )
      )
    end
  end

  describe '#validate_edtf' do
    let(:service) { described_class.new(path: valid_csv_path) }

    before do
      service.instance_variable_set(:@header, 'dcterms:created')
      service.instance_variable_set(:@row_number, 1)
    end

    it 'accepts valid EDTF dates' do
      service.instance_variable_set(:@values, ['2024'])
      service.send(:validate_edtf)
      expect(service.results).to be_empty
    end

    it 'accepts undated exception' do
      service.instance_variable_set(:@values, ['undated'])
      service.send(:validate_edtf)
      expect(service.results).to be_empty
    end

    it 'rejects invalid dates' do
      service.instance_variable_set(:@values, ['not-a-date'])
      service.send(:validate_edtf)
      expect(service.results).to include(
        hash_including(
          header: 'dcterms:created',
          message: '<strong>not-a-date</strong> is not a valid EDTF'
        )
      )
    end
  end
  
  describe '#already_validated?' do
    let(:service) { described_class.new(path: valid_csv_path) }
    
    before do
      service.instance_variable_set(:@header, 'dcterms:type')
      service.instance_variable_set(:@row_number, 1)
      service.instance_variable_set(:@values, ['test_value'])
    end

    it 'returns false for first validation of a value' do
      expect(service.send(:already_validated?, 'test_value')).to be false
    end

    it 'returns true for subsequent validations of the same value' do
      # First validation
      service.send(:already_validated?, 'test_value')
      # Second validation should return true
      expect(service.send(:already_validated?, 'test_value')).to be true
    end

    it 'adds value to validated_values with "validated" message on first check' do
      service.send(:already_validated?, 'test_value')
      
      expect(service.validated_values).to include(
        hash_including(
          header: 'dcterms:type',
          value: 'test_value',
          message: 'validated'
        )
      )
    end

    context 'when value was previously validated as invalid' do
      before do
        service.validated_values << {
          header: 'dcterms:type',
          value: 'test_value',
          message: 'Invalid value'
        }
      end

      it 'returns true and adds error with cached message' do
        expect(service.send(:already_validated?, 'test_value')).to be true
        expect(service.results).to include(
          hash_including(
            header: 'dcterms:type',
            message: 'Invalid value'
          )
        )
      end
    end

    it 'handles different values with same header separately' do
      # First value
      service.send(:already_validated?, 'value1')
      
      # Different value, same header
      expect(service.send(:already_validated?, 'value2')).to be false
    end

    it 'handles same value with different headers separately' do
      # First header
      service.send(:already_validated?, 'test_value')
      
      # Change header
      service.instance_variable_set(:@header, 'dcterms:format')
      expect(service.send(:already_validated?, 'test_value')).to be false
    end
  end
end