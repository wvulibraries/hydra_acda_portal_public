class ValidationService
    def self.new(path:, validate_urls: false)
        ValidationFactory.create(
            path: path,
            validate_urls: validate_urls
        )
    end
end