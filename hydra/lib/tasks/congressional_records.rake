namespace :congressional_records do
  desc "Migrate Acda (Fedora) records into congressional_records/access_controls (Postgres). Dry-run by default - pass DRY_RUN=false to actually write. LIMIT=n to cap how many records are processed. Does NOT migrate file attachments (image/thumbnail/pdf/audio/video) - that is a separate step."
  task migrate: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'true'))
    limit = ENV['LIMIT']&.to_i

    array_columns = CongressionalRecord.columns.select { |c| c.respond_to?(:array?) && c.array? }.map(&:name)

    scope = Acda.all
    total = scope.count
    puts "Found #{total} Acda records in Fedora#{limit ? " (processing first #{limit})" : ''}"
    puts dry_run ? "DRY RUN - no writes will happen" : "LIVE RUN - writing to congressional_records/access_controls"
    puts "NOTE: file attachments are not migrated by this task"
    puts "---"

    processed = 0
    created = 0
    updated = 0
    errors = []

    scope.each do |acda|
      break if limit && processed >= limit
      processed += 1

      begin
        attrs = {
          bulkrax_identifier: acda.bulkrax_identifier,
          identifier: acda.identifier,
          title: acda.title,
          description: acda.description,
          creator: acda.creator,
          names: acda.names,
          publisher: acda.publisher,
          contributing_institution: acda.contributing_institution,
          rights: acda.rights,
          extent: acda.extent,
          dc_type: acda.dc_type,
          record_type: acda.record_type,
          date: acda.date,
          edtf: acda.edtf,
          language: acda.language,
          congress: acda.congress,
          policy_area: acda.policy_area,
          topic: acda.topic,
          location_represented: acda.location_represented,
          collection_title: acda.collection_title,
          physical_location: acda.physical_location,
          collection_finding_aid: acda.collection_finding_aid,
          preview: acda.preview,
          available_at: acda.available_at,
          available_by: acda.available_by,
          project: acda.project,
          queued_job: acda.queued_job
        }

        # Fedora's multi-valued properties come back as an
        # ActiveTriples::Relation object, not a plain Array - Postgres
        # can't serialize that directly as an array column. Force each
        # array-column value to a real Array first, same as Acda's own
        # clear_empty_fields method already does for this exact reason.
        array_columns.each do |col|
          next unless attrs.key?(col.to_sym)
          value = attrs[col.to_sym]
          attrs[col.to_sym] = value.respond_to?(:to_a) ? value.to_a : Array(value)
        end

        record = CongressionalRecord.find_or_initialize_by(id: acda.id)
        is_new = record.new_record?

        if dry_run
          puts "#{is_new ? 'CREATE' : 'UPDATE'} #{acda.id} - title: #{acda.title.inspect}"
        else
          record.assign_attributes(attrs)
          record.save!
          record.discover_groups = acda.discover_groups.to_a
          record.discover_users = acda.discover_users.to_a
          record.read_groups = acda.read_groups.to_a
          record.read_users = acda.read_users.to_a
          record.edit_groups = acda.edit_groups.to_a
          record.edit_users = acda.edit_users.to_a
        end

        is_new ? created += 1 : updated += 1
      rescue StandardError => e
        errors << "#{acda.id}: #{e.class} - #{e.message}"
        puts "ERROR on #{acda.id}: #{e.message}"
      end
    end

    puts "---"
    puts "Processed: #{processed}"
    puts "#{dry_run ? 'Would create' : 'Created'}: #{created}"
    puts "#{dry_run ? 'Would update' : 'Updated'}: #{updated}"
    puts "Errors: #{errors.count}"
    errors.each { |e| puts "  #{e}" }
  end

  desc "Migrate file attachments (image/thumbnail/pdf/audio/video) from Acda (Fedora) into the matching CongressionalRecord via ActiveStorage. Dry-run by default - pass DRY_RUN=false to actually write. LIMIT=n to cap how many Acda records are processed."
  task migrate_files: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'true'))
    limit = ENV['LIMIT']&.to_i

    file_associations = %i[image_file thumbnail_file pdf_file audio_file video_file]

    scope = Acda.all
    total = scope.count
    puts "Found #{total} Acda records#{limit ? " (processing first #{limit})" : ''}"
    puts dry_run ? "DRY RUN - no writes will happen" : "LIVE RUN - attaching files to congressional_records via ActiveStorage"
    puts "---"

    processed = 0
    attached = 0
    skipped_already_attached = 0
    skipped_no_record = 0
    errors = []

    scope.each do |acda|
      break if limit && processed >= limit
      processed += 1

      record = CongressionalRecord.find_by(id: acda.id)
      unless record
        skipped_no_record += 1
        puts "SKIP #{acda.id}: no matching CongressionalRecord (run congressional_records:migrate first)"
        next
      end

      file_associations.each do |assoc|
        begin
          acda_file = acda.send(assoc)
          next unless acda_file.present?

          content = acda_file.content
          next if content.blank?

          target = record.send(assoc)

          if target.attached?
            skipped_already_attached += 1
            next
          end

          filename = acda_file.original_name.presence || "#{acda.id}_#{assoc}"
          content_type = acda_file.mime_type.presence || 'application/octet-stream'

          if dry_run
            puts "ATTACH #{acda.id}.#{assoc} - #{filename} (#{content_type}, #{content.bytesize} bytes)"
          else
            target.attach(io: StringIO.new(content), filename: filename, content_type: content_type)
          end

          attached += 1
        rescue StandardError => e
          errors << "#{acda.id}.#{assoc}: #{e.class} - #{e.message}"
          puts "ERROR on #{acda.id}.#{assoc}: #{e.message}"
        end
      end
    end

    puts "---"
    puts "Acda records processed: #{processed}"
    puts "#{dry_run ? 'Would attach' : 'Attached'}: #{attached}"
    puts "Skipped (already attached): #{skipped_already_attached}"
    puts "Skipped (no matching CongressionalRecord): #{skipped_no_record}"
    puts "Errors: #{errors.count}"
    errors.each { |e| puts "  #{e}" }
  end
end