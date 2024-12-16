# frozen_string_literal: true

# Validations Class
class ValidationsController < ApplicationController
  def upload
  end

  def show
    unless params[:csv_file]&.content_type == 'text/csv'
      flash[:error] = 'Please upload a CSV file'
      return redirect_to validate_path
    end

    @results = validate_file
  rescue CSV::MalformedCSVError
    flash[:error] = 'Invalid CSV file format'
    redirect_to validate_path
  end

  private

  def validate_file
    csv_path = params['csv_file'].tempfile
    csv_data = File.read(csv_path)
    results = []

    headers = CSV.parse(csv_data, headers: true).headers
    invalid_headers = headers - bulkrax_headers
    results << invalid_headers.map { |header| { row: 1, header: header, message: "<strong>#{header}</strong> is an invalid header" } } if invalid_headers.present?

    CSV.parse(csv_data, headers: true).each_with_index do |row, index|
      row_results = validate_row(row: row, row_number: index + 2)
      results << row_results if row_results.present?
    end

    results.flatten
  end

  def validate_row(row:, row_number:)
    validator = ValidationService.new(row, row_number)
    validator.validate
  end

  def bulkrax_headers
    # taking out the 'bulkrax_identifier' field because WVU csv's don't use it
    Bulkrax.field_mappings["Bulkrax::CsvParser"].values.flat_map { |hash| hash[:from] } - ['bulkrax_identifier']
  end
end
