# Validations Class
class ValidationsController < ApplicationController
  def upload
  end

  def show
    @results = validate_file
  end

  def validate_file
    csv_path = params['csv_file'].tempfile
    csv_data = File.read(csv_path)
    @results = []
    CSV.parse(csv_data, headers: true) do |row|
      @results << check_row(row: row)
    end
    @results
  end

  def check_row(row:)
    record_data = row.to_hash.symbolize_keys
    validate_record(data: record_data)
  end

  def validate_record(data:)
    { results: 'ok' }
  end
end
