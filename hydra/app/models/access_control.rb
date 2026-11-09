# One row = one permission grant. Companion model for the access_controls
# table (see db/migrate/20261109120002_create_access_controls.rb).
class AccessControl < ApplicationRecord
  belongs_to :congressional_record

  AGENT_TYPES = %w[person group].freeze
  ACCESS_LEVELS = %w[discover read edit].freeze

  # Mirrors the DB CHECK constraints (20261109120003) at the Rails level too,
  # so you get a friendly validation error instead of only a raw SQL error.
  validates :agent_type, inclusion: { in: AGENT_TYPES }
  validates :access_level, inclusion: { in: ACCESS_LEVELS }
  validates :agent_name, presence: true
end
