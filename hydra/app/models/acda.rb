# Generated Model for Metadata 
class Acda < ActiveFedora::Base
  include Hydra::AccessControls::Permissions

  # Minting ID
  # Overriding Fedoras LONG URI NOT FRIENDLY ID
  def assign_id
    identifier.gsub('.', '').to_s
  end  

  # DC provenance
  # ==============================================================================================================
  # contributing institution property
  property :contributing_institution, predicate: ::RDF::Vocab::DC.provenance, multiple: false do |index|
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

  # DC format
  # ==============================================================================================================
  # edtf property
  property :edtf, predicate: ::RDF::Vocab::DC.created, multiple: false do |index|
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

  # DC language
  # ==============================================================================================================
  # language property
  property :language, predicate: ::RDF::Vocab::DC.language, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC temporal
  # ==============================================================================================================
  # congress property  
  property :congress, predicate: ::RDF::Vocab::DC.temporal, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC isPartOf 
  # ==============================================================================================================
  # collection property   
  property :collection, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/collection'), multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC isPartOf 
  # ==============================================================================================================
  # physical location property   
  property :physical_location, predicate: ::RDF::Vocab::DC.isPartOf, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC source
  # ==============================================================================================================
  # collection finding aid property     
  property :collection_finding_aid, predicate: ::RDF::Vocab::DC.source, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC identifier
  # ==============================================================================================================
  # identifier property   
  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # EDM preview
  # ==============================================================================================================
  # preview property  
  property :preview, predicate: ::RDF::Vocab::EDM.preview, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # EDM isShownAt
  # ==============================================================================================================
  # Avaliable At Property   
  property :available_at, predicate: ::RDF::Vocab::EDM.isShownAt, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC record type
  # ==============================================================================================================
  # Record Type property
  property :record_type, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/recordType'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC subject
  # ==============================================================================================================
  # Policy Area property
  property :policy_area, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/policyArea'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC description
  # ==============================================================================================================
  # description property
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC subject
  # ==============================================================================================================
  # Topic property
  property :topic, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/topic'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end   

  # DC subject
  # ==============================================================================================================
  # Names property
  property :names, predicate: ::RDF::Vocab::DC.subject, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  
  
  # DC spatial
  # ==============================================================================================================
  # Location Represented property
  property :location_represented, predicate: ::RDF::Vocab::DC.spatial, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end 

  # DC type
  # ==============================================================================================================
  # type property
  property :dc_type, predicate: ::RDF::Vocab::DC.type, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC format
  # ==============================================================================================================  
  # type extent
  property :extent, predicate: ::RDF::Vocab::DC.format, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end  

  # DC publisher
  # ==============================================================================================================
  # publisher property
  property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # PROJECT IDENTIFIER
  # ==============================================================================================================
  # used in the search builder to target only records from this collection
  property :project, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/project'), multiple: true do |index|
    index.as :stored_searchable, :facetable
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
