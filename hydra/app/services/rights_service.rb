# frozen_string_literal: true

# Provide select options for the copyright status (edm:rights) field
class RightsService < QaSelectService
  def initialize(_authority_name = nil)
    super('rights')
  end
end
