# frozen_string_literal: true

class ValidateJob < ApplicationJob
  queue_as :default

  def perform(path:, file_name:, mail_to:)
    content = ValidationService.new(path:).validate

    email_depositor(mail_to:, file_name:, content:, path:)
  end

  def email_depositor(mail_to:, file_name:, content:, path:)
    ValidationMailer.email_validation(mail_to:, file_name:, content:).deliver_now

    File.delete(path) if File.exist?(path)
  rescue Net::OpenTimeout => e
    Rails.logger.error("Emailer may not be set up correctly. #{e}")
  end
end
