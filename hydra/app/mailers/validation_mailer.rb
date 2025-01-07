# frozen_string_literal: true

class ValidationMailer < ApplicationMailer
  def email_validation(mail_to:, file_name:, content:)
    @content = content

    # content is used by app/views/validation_mailer/email_validation.html.erb
    # to prepare body of email.
    mail(
      :to => mail_to,
      :subject => "Validation results for file: #{file_name}",
      :date => Time.now,
      content_type: 'text/html'
    )   
  end
end
