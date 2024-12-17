# frozen_string_literal: true

class ValidateJob < ApplicationJob
  queue_as :default

  def perform(path:, file_name:, mail_to:)
    results = ValidationService.new(path: path).validate
    ## clean up file after processing
    if File.exist?(path)
      File.delete(path)
    end
    # send the email
    email_depositor(mail_to:, file_name:, content: results)
  end

  def email_depositor(mail_to:, file_name:, content:)
    ValidationMailer.email_validation(mail_to:, file_name:, content:).deliver_now
  end
end