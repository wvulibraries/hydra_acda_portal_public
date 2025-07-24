FactoryBot.define do
  factory :acda do
    # Basic metadata
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

    # Optional metadata
    publisher            { ["Sample Publisher"] }
    project              { ["Test Project"] }

    # Ensures default ActiveFedora callbacks still run
    after(:build) do |acda|
      # Simulate Fedora ID assignment if needed
      acda.id ||= SecureRandom.uuid
    end
  end
end
