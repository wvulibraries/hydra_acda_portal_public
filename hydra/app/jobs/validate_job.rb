# frozen_string_literal: true

class ValidateJob < ApplicationJob
  queue_as :default

  def perform(path:, mail_to:)
    @results = ValidationService.new(path: @path).validate
  end
end