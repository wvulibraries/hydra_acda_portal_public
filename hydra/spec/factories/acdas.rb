FactoryBot.define do
  factory :acda do
    # Required metadata
    title                { "Sample ACDA Record" }
    creator              { ["John Doe"] }
    date                 { ["2024-01-01"] }
    rights               { "Public Domain" }
    language             { ["English"] }
    description          { "This is a sample ACDA object for testing." }
    identifier           { "https://test.com/sample_record" }
    available_at         { "https://example.com/record" }
    available_by         { "https://example.com/download/file.pdf" }
    preview              { "https://example.com/thumbnail.jpg" }
    record_type          { ["Image"] }
    policy_area          { ["History"] }
    dc_type              { "Image" }

    # Optional metadata
    publisher            { ["Sample Publisher"] }
    project              { ["Test Project"] }
    contributing_institution { "Sample Institution" }
    collection_title     { "Test Collection" }
    physical_location    { "Sample Library" }
    collection_finding_aid { "https://example.com/finding_aid" }
    extent               { "1 item" }
    congress             { [] }
    names                { [] }
    topic                { [] }
    location_represented { [] }
    bulkrax_identifier   { "bulkrax-123" }

    # Required field for job tracking logic (can override in tests)
    queued_job           { nil }

    # Assign a unique Fedora-style ID
    after(:build) do |acda|
      acda.id ||= SecureRandom.uuid
    end
  end
end
