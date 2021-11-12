class ImportMailer < ApplicationMailer
  def email(*email_details)
    @to, @subject, @body = email_details
    mail(to: @to, subject: @subject, body: @body)
  end
end
