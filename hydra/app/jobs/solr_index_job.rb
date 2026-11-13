# Keeps Solr in sync with CongressionalRecord changes. ActiveFedora used to
# do this automatically on every save; now that CongressionalRecord is a
# plain ActiveRecord model, nothing pushed to Solr except the manual
# `rake congressional_records:reindex` task - so without this, every
# create/update (including every Bulkrax import) was invisible in search
# until someone remembered to run that task by hand.
class SolrIndexJob < ApplicationJob
  queue_as :default

  def perform(id)
    record = CongressionalRecord.find_by(id: id)
    return delete_from_solr(id) if record.nil?

    solr_connection.add(record.to_solr)
    solr_connection.commit
  end

  private

  def delete_from_solr(id)
    solr_connection.delete_by_id(id)
    solr_connection.commit
  end

  def solr_connection
    CatalogController.blacklight_config.repository_class.new(CatalogController.blacklight_config).connection
  end
end