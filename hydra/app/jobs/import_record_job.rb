class ImportRecordJob < ApplicationJob
  include ImportLibrary

  queue_as :default

  def perform(export_path, record)
    # remove . in identifier
    id = record['idno'].gsub('.', '').to_s

    # record exists
    record_exists = Acda.where(identifier: id).first

    if record_exists.nil?
      ImportLibrary.import_record(id, ImportLibrary.modify_record(export_path, record))
    else          
      ImportLibrary.update_record(record_exists, ImportLibrary.modify_record(export_path, record))
    end
  end

end