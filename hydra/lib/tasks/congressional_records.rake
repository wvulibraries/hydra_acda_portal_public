namespace :congressional_records do
  desc "Push CongressionalRecord-generated Solr documents into the existing Solr index (same documents Acda produces today via ActiveFedora indexing - verified field-for-field match). Dry-run by default - pass DRY_RUN=false to actually write. LIMIT=n to cap how many records are processed."
  task reindex: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'true'))
    limit = ENV['LIMIT']&.to_i

    scope = CongressionalRecord.all
    scope = scope.limit(limit) if limit
    total = scope.count
    puts "Found #{total} CongressionalRecords#{limit ? " (processing first #{limit})" : ''}"
    puts dry_run ? "DRY RUN - no writes to Solr will happen" : "LIVE RUN - pushing documents to Solr"
    puts "---"

    solr_connection = CatalogController.blacklight_config.repository_class.new(CatalogController.blacklight_config).connection

    processed = 0
    errors = []

    scope.find_each do |record|
      processed += 1
      begin
        doc = record.to_solr
        if dry_run
          puts "WOULD INDEX #{record.id} (#{doc.keys.size} fields)"
        else
          solr_connection.add(doc)
          solr_connection.commit
        end
      rescue StandardError => e
        errors << "#{record.id}: #{e.class} - #{e.message}"
        puts "ERROR on #{record.id}: #{e.message}"
      end
    end

    puts "---"
    puts "Processed: #{processed}"
    puts "Errors: #{errors.count}"
    errors.each { |e| puts "  #{e}" }
  end
end
