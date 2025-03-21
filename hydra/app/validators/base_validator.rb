frozen_string_literal: true

class BaseValidator
    attr_reader :header, :value, :options

    def initialize(header, value, options: {})
        @header = header
        @value = value
        @options = options
    end

    def validate
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def valid?
        validate[:valid]
    end

    def error_message
        validate[:message]
    end

    protected 

    def format_error(message)
        "<strong>#{value}</strong> #{message}"
    end
end