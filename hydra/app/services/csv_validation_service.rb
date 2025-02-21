class CsvValidationService 
    attr_reader :path, :validators, :results, :validated_values

    def initialize(path:, validators:)
        @path = path
        @validators = validators
        @results = []
        @validated_values = []
    end

    def validate
        validate_file_exists
        return results if has_errors?

        csv_data = File.read(path)
        validate_headers(csv_data)
        return results if has_errors? 

        validate_rows(csv_data)
        results
    end

    private 

    def validate_file_exists
        return if File.exist?(path)
        
        results << {
          row: 1,
          header: "",
          message: "File missing at #{path}"
        }
    end
end