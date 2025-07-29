# frozen_string_literal: true

class ImportMailer < ApplicationMailer
  def email(*email_details)
    @to, @subject, @body = email_details
    mail(to: @to, subject: @subject, body: @body)
  end

  def import_notification(mail_to:, file_name:, status:)
    @status = status
    mail(
      to: mail_to,
      subject: "Import results for file: #{file_name}",
      date: Time.now,
      content_type: 'text/html'
    )
  end
end
