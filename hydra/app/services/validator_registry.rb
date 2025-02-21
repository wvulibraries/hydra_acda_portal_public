# app/services/validator_registry.rb
class ValidatorRegistry
    def self.default(validate_urls: false)
        new(
            url_validation: validate_urls,
            validators: default_validators
        )
    end

    def initialize(url_validation: false, validators: {})
        @url_validation = url_validation
        @validators = validators
    end

    def has_validator?(header)
        @validators.key?(header)
    end
    
    def for(header)
        @validators[header]
    end

    private 

    def self.default_validators 
        { dc}
    end
end
