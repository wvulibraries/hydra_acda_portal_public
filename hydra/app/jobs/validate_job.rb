# frozen_string_literal: true

class ValidateJob < ApplicationJob
  queue_as :default

  def perform(path:, file_name:, mail_to:)
    content = ValidationService.new(path:).validate

    email_depositor(mail_to:, file_name:, content:, path:)
  end

  def email_depositor(mail_to:, file_name:, content:, path:)
debugger
    ValidationMailer.email_validation(mail_to:, file_name:, content:).deliver_now

    File.delete(path) if File.exist?(path)
  end
end
