# frozen_string_literal: true

class EdtfValidator < BaseValidator
    EDTF_EXCEPTION = 'undated'.freeze
    
    def validate
      if invalid_edtf?(value)
        { valid: false, message: format_error("is not a valid EDTF") }
      else
        { valid: true, message: nil }
      end
    end
    
    private
    
    def invalid_edtf?(date)
      date != EDTF_EXCEPTION && EDTF.parse(date).nil?
    end
end