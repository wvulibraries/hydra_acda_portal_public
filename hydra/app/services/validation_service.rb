# frozen_string_literal: true

class ValidationService
  def initialize(row, row_number)
    @row = row
    @row_number = row_number
    @results = []
    @header = nil
    @values = []
  end

  def validate
    headers = @row.headers

    headers.each do |header|
      @header = header
      @values = @row[header]&.split("\;")&.map(&:strip)

      case header
      when 'dcterms:provenance'
        validate_free_text
      when 'dcterms:title'
        validate_free_text
      when 'dcterms:date'
        validate_free_text
      when 'dcterms:created'
        validate_edtf
      when 'dcterms:creator'
        search_lc_linked_data_service('http://id.loc.gov/authorities/names')
      when 'dcterms:rights'
        validate_local_authorities('rights')
      when 'dcterms:language'
        validate_iso_639_2
      when 'dcterms:temporal'
        validate_local_authorities('congress')
      when 'dcterms:relation'
        validate_free_text
      when 'dcterms:isPartOf'
        validate_free_text
      when 'dcterms:source'
        validate_url
      when 'dcterms:identifier'
        validate_free_text # TODO: check for uniqueness?
      when 'edm:preview'
        validate_url if @values.present?
      when 'edm:isShownBy'
        validate_url
      when 'edm:isShownAt'
        validate_url
      when 'dcterms:http://purl.org/dc/terms/type'
        search_getty_aat # TODO
      when 'dcterms:type'
        validate_local_authorities('types')
      when 'dcterms:subject'
        validate_local_authorities('policy_area') if @values.present?
      when 'http://lib.wvu.edu/hydra/subject'
        search_lc_linked_data_service('http://id.loc.gov/authorities/subjects')
      when 'dcterms:contributor'
        search_lc_linked_data_service('http://id.loc.gov/authorities/names')
      when 'dcterms:spatial'
        search_tgn # TODO
      when 'dcterms:format'
        validate_free_text if @values.present?
      when 'dcterms:publisher'
        validate_free_text if @values.present?
      when 'dcterms:description'
        validate_free_text if @values.present?
      else
        add_error("Header not recognized")
      end
    end

    @results
  end

  private

  def add_error(message)
    @results << {
      row: @row_number,
      header: @header,
      message: message
    }
  end

  def validate_free_text
    add_error("Missing required value") if @values.empty?
  end

  def validate_edtf
    @values.each do |value|
      add_error("<strong>#{value}</strong> is not a valid EDTF") if EDTF.parse(value).nil?
    end
  end

  def validate_local_authorities(authority)
    qa = QaSelectService.new(authority)

    @values.each do |value|
      add_error("<strong>#{value}</strong> is not valid") unless qa.authority.find(value)['active']
    end
  end

  def validate_iso_639_2
    @values.each do |value|
      add_error("<strong>#{value}</strong> is not a valid language code") unless ::ISO_639.find_by_code(value)&.compact_blank&.include?(value)
    end
  end

  def validate_url(required: false)
    @values.each do |value|
      add_error("<strong>#{value}</strong> is an invalid URL format") unless value.starts_with?('http')
    end
  end

  def search_lc_linked_data_service(linked_data_service)
    @values.each do |value|
      base_url = "https://id.loc.gov/search/"
      lds = "cs:#{linked_data_service}" if linked_data_service.present?
      params = { q: [lds, "\"#{value}\""], format: "atom" }
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get(uri)
      doc = Nokogiri::XML(response)

      result = doc.xpath('//atom:entry', 'atom' => 'http://www.w3.org/2005/Atom').select do |entry|
        entry.at_xpath('atom:title', 'atom' => 'http://www.w3.org/2005/Atom')&.text == value
      end

      add_error("<strong>#{value}</strong> was not found in LC Linked Data Service") if result.empty?
    end
  end

  def search_getty_aat
    @values.each do |value|
      endpoint = "https://vocab.getty.edu/sparql"
      query = <<~SPARQL
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        SELECT ?concept ?label WHERE {
          ?concept a skos:Concept ;
                    skos:prefLabel "#{value}"@en .
        }
      SPARQL

      params = {
        query: query,
        format: 'json'
      }

      uri = URI(endpoint)
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get_response(uri)
      unless response.is_a?(Net::HTTPSuccess)
        add_error("Error: #{response.message}")
        return
      end

      results = JSON.parse(response.body)['results']['bindings']

      add_error("<strong>#{value}</strong> was not found in Getty AAT") if results.empty?
    end
  end

  def search_tgn
    # TODO: need to figure out how to query TGN
    # https://www.getty.edu/research/tools/vocabularies/tgn/index.html
  end
end
