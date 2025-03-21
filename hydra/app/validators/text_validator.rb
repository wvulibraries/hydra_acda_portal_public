# frozen_string_literal: true

class TextValidator < BaseValidator
    def validate
      if value.to_s.empty?
        { valid: false, message: "Missing required value" }
      else
        { valid: true, message: nil }
      end
    end
end