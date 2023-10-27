# frozen_string_literal: true

# Provide select options for the copyright status (edm:rights) field
class CongressService < QaSelectService
  def initialize(_authority_name = nil)
    super('congress')
  end
end
