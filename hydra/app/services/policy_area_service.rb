# frozen_string_literal: true

# Provide select options for the copyright status (edm:rights) field
class PolicyAreaService < QaSelectService
  def initialize(_authority_name = nil)
    super('policy_area')
  end
end
