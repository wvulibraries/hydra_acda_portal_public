# frozen_string_literal: true

class ValidationMailerPreview < ActionMailer::Preview
  # view preview at: http://localhost:3000/rails/mailers/validation_mailer/email_validation
  def email_validation
    mail_to = 'test@test.test'
    file_name = 'test.csv'
    content = [
      { row: 2, header: "dcterms:creator", message: "<strong>Invalid Author Name</strong> was not found in LC Linked Data Service" },
      { row: 3, header: "dcterms:created", message: "<strong>2023-13-45</strong> is not a valid EDTF" },
      { row: 4, header: "dcterms:language", message: "<strong>xxx</strong> is not a valid language code" },
      { row: 5, header: "dcterms:spatial", message: "<strong>Invalid City (city)</strong> was not found in Getty TGN" },
      { row: 6, header: "edm:isShownAt", message: "<strong>invalid-url</strong> is an invalid URL format" },
      { row: 7, header: "dcterms:type", message: "<strong>Invalid Type</strong> is not valid" },
      { row: 8, header: "invalid_header", message: "<strong>invalid_header</strong> is an invalid header" },
      { row: 9, header: "dcterms:title", message: "Missing required value" }
    ]

    ValidationMailer.email_validation(mail_to:, file_name:, content:)
  end
end
