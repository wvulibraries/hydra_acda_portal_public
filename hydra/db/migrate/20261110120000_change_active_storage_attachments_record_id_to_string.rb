# Fix: active_storage_attachments.record_id was created as bigint (Rails'
# normal default), but CongressionalRecord.id is a string (Fedora-style
# IDs). Every attach silently wrote record_id=0 instead of the real id -
# confirmed directly against bad data from a live test run - because
# Rails casts a non-numeric string to 0 rather than raising. Safe to
# change for the whole polymorphic table since CongressionalRecord is the
# only model in this app using ActiveStorage.
class ChangeActiveStorageAttachmentsRecordIdToString < ActiveRecord::Migration[7.0]
  def change
    change_column :active_storage_attachments, :record_id, :string
  end
end