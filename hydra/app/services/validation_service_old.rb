# frozen_string_literal: true

class ValidationService
  include ApplicationHelper

  class_attribute :split_on, default: ("\;")

  MAPPINGS = {
    'dcterms:provenance' => -> { validate_free_text },
    'dcterms:title' => -> { validate_free_text },
    'dcterms:date' => -> { validate_free_text },
    'dcterms:created' => -> { validate_edtf },
    'dcterms:creator' => -> { search_lc_linked_data_service('http://id.loc.gov/authorities/names', 'LCNAF') },
    'dcterms:rights' => -> { validate_local_authorities('rights') },
    'dcterms:language' => -> { validate_iso_639_2 },
    'dcterms:temporal' => -> { validate_local_authorities('congress') },
    'dcterms:relation' => -> { validate_free_text },
    'dcterms:isPartOf' => -> { validate_free_text },
    'dcterms:source' => -> { validate_url },
    'dcterms:identifier' => -> { validate_free_text }, # TODO: check for uniqueness?
    'edm:preview' => -> { validate_url if values.present? },
    'edm:isShownBy' => -> { validate_url },
    'edm:isShownAt' => -> { validate_url },
    'dcterms:http://purl.org/dc/terms/type' => -> { search_getty_aat },
    'dcterms:type' => -> { validate_local_authorities('types') },
    'dcterms:subject' => -> { validate_local_authorities('policy_area') if values.present? },
    'dcterms:http://purl.org/dc/elements/1.1/subject' => -> { search_lc_linked_data_service('http://id.loc.gov/authorities/subjects', 'LCSH') },
    'dcterms:contributor' => -> { search_lc_linked_data_service('http://id.loc.gov/authorities/names', 'LCNAF') },
    'dcterms:spatial' => -> { search_getty_tgn if values.present? },
    'dcterms:format' => -> { validate_free_text if values.present? },
    'dcterms:publisher' => -> { validate_free_text if values.present? },
    'dcterms:description' => -> { validate_free_text if values.present? }
  }

  EDTF_EXCEPTION = 'undated'.freeze
  CREATOR_EXCEPTION = 'unknown'.freeze

  class_attribute :actions, default: MAPPINGS
  attr_accessor :path, :validate_urls, :row, :row_number, :results, :validated_values, :header, :values

  def initialize(path:, validate_urls: false)
    @path = path
    @validate_urls = validate_urls
    @results = []
    @validated_values = []
  end

  def validate
    csv_path = path
    if File.exist?(csv_path)
      csv_data = File.read(csv_path)

      headers = CSV.parse(csv_data, headers: true).headers
      invalid_headers = headers - bulkrax_headers
      invalid_headers.map { |header| results << { row: 1, header: header, message: "<strong>#{header}</strong> is an invalid header" } } if invalid_headers.present?
      CSV.parse(csv_data, headers: true).each_with_index do |row, index|
        validate_row(row: row, row_number: index + 2)
      end
    else
      results << { row: 1, header: "", message: "File missing at #{csv_path}" }
    end

    results
  end

  private

  def validate_row(row:, row_number:)
    @row = row
    @row_number = row_number

    row.each_pair do |key, value|
      @header = key
      @values = split_term(value:)
      validate_content
    end
    true
  end

  def bulkrax_headers
    # taking out the 'bulkrax_identifier' field because WVU csv's don't use it
    Bulkrax.field_mappings["Bulkrax::CsvParser"].values.flat_map { |hash| hash[:from] } - ['bulkrax_identifier']
  end

  def validate_content
    action = actions[header]
    instance_exec(&action) if action
  end

  # Use bulkrax split character to break into multiple values
  # Always return an array since split returns an array
  def split_term(value:)
    # ensure we always return an array for consistency with split function
    term = Array.wrap(value)
    return term if value.nil? || check_split[header] == false
    value.split(split_on).map(&:strip)
  end

  # Use Bulkrax to determine if this header is one we split
  def check_split
    @split_headers ||= begin
      new_hash = {}
      mappings = Bulkrax.field_mappings["Bulkrax::CsvParser"]
      mappings.each do |_, value|
        value[:from].each do |from_value|
          new_hash[from_value] = value.fetch(:split, false)
        end
      end
      new_hash
    end
  end

  def add_error(value: nil, message:)
    results << {
      row: row_number,
      header: header,
      message: message,
    }

    validated_value_hash = validated_values.find { |hash| hash[:header] == header && hash[:value] == value }

    if validated_value_hash
      validated_value_hash[:message] = message
    else
      validated_values << {
        header: header,
        message: message,
        value: value
      }
    end
  end

  def validate_free_text
    values.each do |value|
      add_error(value: value, message: "Missing required value") if value.empty?
    end
  end

  def validate_edtf
    values.each do |value|
      next if already_validated?(value)

      add_error(value:, message: "<strong>#{value}</strong> is not a valid EDTF") if invalid_edtf?(value)
    end
  end

  def invalid_edtf?(date)
    date != EDTF_EXCEPTION && EDTF.parse(date).nil?
  end

  def validate_local_authorities(authority)
    qa = QaSelectService.new(authority)

    values.each do |value|
      next if already_validated?(value)

      add_error(value:, message: "<strong>#{value}</strong> is not valid") unless qa.authority.find(value)['active']
    end
  end

  def validate_iso_639_2
    values.each do |value|
      next if already_validated?(value)

      add_error(value:, message: "<strong>#{value}</strong> is not a valid language code") unless ::ISO_639.find_by_code(value)&.compact_blank&.include?(value)
    end
  end

  def validate_url(required: false)
    values.each do |value|
      next if already_validated?(value)

      add_error(value:, message: "<strong>#{value}</strong> is an invalid URL format") unless is_active_url?(value)
    end
  end

  def is_active_url?(value)
    return value.starts_with?('http') unless validate_urls

    super
  end

  def search_lc_linked_data_service(linked_data_service, dataset)
    values.each do |value|
      next if already_validated?(value)
      next if header == 'dcterms:creator' && value == CREATOR_EXCEPTION

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

      add_error(value:, message: "<strong>#{value}</strong> was not found in LC Linked Data Service (#{dataset})") if result.empty?
    end
  end

  def search_getty_aat
    values.each do |value|
      next if already_validated?(value)

      results = search_getty_aat_sparql(value) || search_getty_aat_online_tool(value) || {}

      unless results.present? || results.fetch('concept', nil)&.fetch('value', nil)&.include?('http://vocab.getty.edu/aat/')
        add_error(value:, message: "<strong>#{value}</strong> was not found in Getty AAT")
      end
    end
  end

  def search_getty_aat_sparql(value)
    endpoint = "https://vocab.getty.edu/sparql"
    query = <<~SPARQL
      SELECT ?concept {
        ?concept a skos:Concept;
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
      add_error(value:, message: "Error: #{response.message}")
      return
    end

    JSON.parse(response.body)['results']['bindings'][0]
  end

  # If the sqarql query doesn't return with results we have this scraper as a backup.
  # Sometimes we're finding things in one place and not the other.
  def search_getty_aat_online_tool(value)
    match_data = value.match(/^(.*?)\s*\((.*?)\)$/)
    find, note = match_data ? [match_data[1], match_data[2]] : [value, '']

    url = "https://www.getty.edu/vow/AATServlet?english=N&find=#{find}&logic=AND&page=1&note=#{note}"
    doc = Nokogiri::HTML(URI.open(url))
    selector = "//td[@valign='bottom' and @colspan='2']/span[@class='page']/a/b[text()='#{value}']"
    doc.at_xpath(selector)
  end

  # This is a very fragile approach to parsing the Getty TGN because
  # it scrapes the HTML page and relies on the structure of the page.
  # Ideally, we want to utilize the SPARQL endpoint for the Getty TGN
  # as well but it doesn't seem to have the functionality to search by
  # place type or at least we haven't found a way yet.
  def search_getty_tgn
    values.each do |value|
      next if already_validated?(value)

      # We split the value because it looks something like "Maryland (state)" and this is
      # what we want to store.  However we need to search Getty TGN with the name and
      # place type separately.
      match_data = value.match(/^(.*?)\s*\((.*?)\)$/)
      next add_error(value:, message: "#{value} is not valid") unless match_data

      name, place_type = match_data[1], match_data[2]
      url = "https://www.getty.edu/vow/TGNServlet?english=Y&find=#{name}&place=#{place_type}&page=1&nation="
      doc = Nokogiri::HTML(URI.open(url))
      selector = "//td[@valign='bottom' and @colspan='2']/span[@class='page'][contains(., '(#{place_type})') and .//a/b[text()='#{name}']]"
      element = doc.at_xpath(selector)

      if element.nil? || element.children[0].text.strip != name || !element.children[1].text.include?(place_type)
        add_error(value:, message: "<strong>#{value}</strong> was not found in Getty TGN")
      end
    end
  end

  # checks if the value has already been previously validated,
  # if so then it will use the result of that instead of rechecking
  def already_validated?(value)
    validated_value_hash = validated_values.find { |hash| hash[:header] == header && hash[:value] == value }

    if validated_value_hash
      add_error(value:, message: validated_value_hash[:message]) if validated_value_hash[:message] != 'validated'
      true
    else
      validated_values << { header:, value:, message: 'validated'}
      false
    end
  end
end
