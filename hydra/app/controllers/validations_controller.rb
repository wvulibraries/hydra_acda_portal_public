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
end
