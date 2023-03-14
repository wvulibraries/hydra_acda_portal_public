# Generated Model for Metadata 
class Acda < ActiveFedora::Base
  include Hydra::AccessControls::Permissions

  # Minting ID
  # Overriding Fedoras LONG URI NOT FRIENDLY ID
  def assign_id
    identifier.gsub('.', '').to_s
  end  

  # identifier
  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # contributing institution
  property :contributing_institution, predicate: ::RDF::Vocab::DC.contributor, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC Title
  # ==============================================================================================================
  # title property
  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC date
  # ==============================================================================================================
  # date property
  property :date, predicate: ::RDF::Vocab::DC.date, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # date
  property :edtf, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/edtf'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC creator
  # ==============================================================================================================
  # creator property
  property :creator, predicate: ::RDF::Vocab::DC.creator, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC rights
  # ==============================================================================================================
  # rights property
  property :rights, predicate: ::RDF::Vocab::DC.rights, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC rights
  # ==============================================================================================================
  # rights property
  property :rights2, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/rights2'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # ==============================================================================================================
  # alternate identifier
  property :alternate_identifier, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/alternateIdentifier'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC language
  # ==============================================================================================================
  # language property
  property :language, predicate: ::RDF::Vocab::DC.language, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # record_type
  property :record_type, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/recordType'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # collection 
  property :collection, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/collection'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # collection finding aid
  property :collection_finding_aid, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/collectionFindingAid'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC description
  # ==============================================================================================================
  # description property
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # subject policy
  property :subject_policy, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/subjectPolicy'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # subject names
  property :subject_names, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/subjectNames'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # subject topical
  property :subject_topical, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/subjectTopical'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # coverage congress
  property :coverage_congress, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/subjectTemporal'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # coverage spatial
  property :coverage_spatial, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/subjectSpatial'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC type
  # ==============================================================================================================
  # type property
  property :dc_type, predicate: ::RDF::Vocab::DC.type, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # type extent
  property :extent, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/extent'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC publisher
  # ==============================================================================================================
  # publisher property
  property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # viaf_ids property
  property :viaf_ids, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/viafIds'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # full text
  property :full_text, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/fullText'), multiple: false do |index|
    index.type :text
    index.as :stored_searchable
  end 

  # PROJECT IDENTIFIER
  # ==============================================================================================================
  # used in the search builder to target only records from this collection
  property :project, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/project'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  # PROJECT IDENTIFIER
  # ==============================================================================================================
  property :bulkrax_identifier, predicate: ::RDF::URI("https://hykucommons.org/terms/bulkrax_identifier"), multiple: false do |index|
    index.as :stored_searchable
  end

  directly_contains :files, has_member_relation: ::RDF::URI('http://pcdm.org/models#File'), class_name: 'AcdaFile'

  # image property
  directly_contains_one :image_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Image'),
                                     class_name: 'AcdaFile'

  # thumbnail property
  directly_contains_one :thumbnail_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#ThumbnailImage'),
                                         class_name: 'AcdaFile'

  # pdf property
  directly_contains_one :pdf_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Document'),
                                   class_name: 'AcdaFile'

  # audio property
  directly_contains_one :audio_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Audio'),
                                     class_name: 'AcdaFile'

  # video property
  directly_contains_one :video_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Video'),
                                     class_name: 'AcdaFile'  
end
