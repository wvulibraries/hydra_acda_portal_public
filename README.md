# WVU Hydra Repo (Hydra 11)

This repo was created with the intention of being our main hydra head for while.  The goal is to implement hydra 11 in a docker container while also scripting in things to generate our new hydra heads every time we have to make a new "head" or repository.  

## Contents
- Hydra
  - This folder contains a new rails application, generated in rails 5.0.1 and all assets bundled in from the hydra core gem.  Note this isn't the hydra-head gem, it is the core hydra.  
  - A `bin/rails generate hydra:install` has also been run.  
  - An import folder has been created and is the place to start when trying to import the exports from MFCS.
  - Style and JavaScript files have been added for WVU Customization  
  - Images have been added that are used in the views and in some of the more customized aspects of the hydra heads.   
- WVU Setup
  - This has a ruby class that runs as a project generator replacing variable names in various folders and files.  This is done in a way to try and do minimal work getting a hydra head up and running.  Things that can't be automated are export scripts and import scripts.   

----

# Setup Instructions

The following will walk you through setting up the new hydra head.  Understand that there will be manual tasks that must be done outside of this before you know if everything worked properly.  

## Copy and Rename

Copy and rename this directory from git to your desktop.  Name it `hydra-#{projectname}` for consistancy.  

## REMOVE GIT

This is an important step.  In creating new hydra repos, we don't want to over-ride this current repo.  
- Be sure you are in the root of this github repo and type `sudo rm -rf .git`
- Alternately if you can see hidden folders you can use your GUI to look up the `.git` directory and delete it manually.  

## SETUP FILE
Using the terminal change directory to wvu_setup directory.  From this directory you will see a setup.rb file.  Open this file and change the information for your specific repository.   

### BASIC SETUP

 - 'TestModelName' :: Change this to your model name using CamelCase writing.  
 - 'tdna' :: Change this to your project abbreviation or name that is often generated from the MFCS export.  
 - 'test collection name' :: Change this to whatever name you want your collection to be.
 - **ALL OF THESE ARE CASE SENSITIVE**

## Executing the File

- The system requirements for each system may be different.  The file was given executable permissions, make sure this has carried over to your system.  Also make sure that the first line reads as
`#!/usr/bin/env ruby`.  This ensures the the file will be run as a ruby file and an executable.  
- `cd wvu_setup`
- `ruby setup.rb`

## After File Executes
- Delete wvu-setup directory
- Verify that Git was Deleted
- Setup the New Github Link 

## Hydra Head Manual Setups 
There isn't any way to script all of this without lots of pre-planning and forcing hydra to adhear to a certain standard. 

### Models 
There are three really important models in the new hydra setups.  
- [MAIN_MODEL](http://www.rubydoc.info/github/projecthydra/active_fedora/ActiveFedora/Base) :: Contains your metadata.
- [image_file.rb](http://www.rubydoc.info/github/projecthydra/active_fedora/ActiveFedora/File) :: Used in the main model to insert the file into fedora and collection metadata on the file. (Size, Type, Mime, Etc) 
- search_builder.rb :: Is the file that you'll use to limit the collection to a specific project.  This is important to be sure your project only searches and filters on the one your currently viewing.  Even more important when referencing a project that doesn't need imported and pulls directly from another source as many collections do with the WVCP collection.  

MAIN_MODEL which will later be named, the model name you setup in the setup scripts will have to setup with various properties mapped to dublic core, or another standard that has been setup in the hydra community.  Check out the [RDF Vocab and Standards](https://github.com/ruby-rdf/rdf-vocab). 

### Helpers 
Application helper has definitions for the keywords, meta-description, and application name.  Some of this needs changed, do this by going to `hydra/helpers/application_helper.rb` 

### Catalog Controller 

The catalog controller is a file that must be setup form specific to your hydra head and your data. The key thing to remember here, is that the catalog is searching solr, not fedora.  The data that your going to get and index needs to be the solr params that were saved during the import.  Your also going to have to correlate these items to the mappings in your model.  

Example: 

--- Catalog Controller --- 

```ruby
  config.add_search_field('description') do |field|
    description_field = Solrizer.solr_name("description", :stored_searchable)
    field.solr_local_parameters = {
      qf: description_field,
      pf: description_field
    }
  end
```

--- Model --- 

```ruby
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.type :text
    index.as :stored_searchable
  end
```

# Import and Export Scripts

This is a huge step in the hydra head process. In the github there is a project called mfcs-exports.  These are created from MFCS as a way to import metadata and images for various reasons.  The first step is to setup an export using JSON, some have XML exports, but lets try to make all of them JSON for our uses. The import script will then consist of a json parse and insert into database.  

For import create a new directory called import and make the file import.rb. Use existing projects as an example, but understand each one is different based on the items exported from MFCS.  GBE is the most recent.  

To import files use the following commands
- `bash -c "clear && docker exec -it {container} sh"` to open up a session in the new container 
- `RAILS_ENV=development ruby import/import.rb` to run an import into the fedora and solr dev sections
- `RAILS_ENV=development ruby import/explode_fcrepo_solr.rb` to clear the development databases **ONLY DO IN DEVELOPMENT NEVER PROD** This should be **primarily used for testing import scripts**.  

## Development Mode 


## Potential Bugs 


### Database Issues 
*If* you get an error it might be with the database make sure you change it in your config file to what your database is named thats in your compose file.  Alternatively it could be in your configuration files of the docker-compose file, or in the `hydra/configs` 

- `docker exec -it {container} rake db:create` 
- `docker exec -it {container} rake db:migrate` 

### VPN 
You must have VPN access in development to access the fedora and solr storage, it will not load, import, or delete without being on the VPN or being a recongized server that has access to the databases.  

### Image viewers 
For each project you will have to configure to the type of data your viewing.  You may also have to-rework this functionality when dealing with peformance and visual aspects.

### Customization 
For each project a custom background banner needs to be made, also including any custom items that the project is deemed to need.  


# OAI-PMH 
Documentation for setting up OAI-PMH stuff.

## DC Terms Mappings and Limits: 
- title
- creator
- subject
- publisher
- date
- type
- identifier
- language
- source
- rights
- format

## Catalog Controller for OAI
```ruby 
include BlacklightOaiProvider::CatalogControllerBehavior
``` 

`configure_blacklight block`
```ruby 
    ## OAIPMH
    config.oai = {
      provider: {
        repository_name: 'George Bird Evans Collection',
        repository_url: 'https://gbe.lib.wvu.edu',
        record_prefix: 'https://gbe.lib.wvu.edu/catalog/',
        admin_email: 'djdavis@mail.wvu.edu'
      },
      document: {
        limit: 25
      }
    }
```

## Solr Document 
`solr_document.rb`
```ruby
  include BlacklightOaiProvider::SolrDocumentBehavior
  use_extension Blacklight::Document::DublinCore

  field_semantics.merge!(
    alternative: 'collection_name_tesim',
    source:      'collection_number_tesim',
    identifier:  'identifier_tesim',
    title:       'title_tesim',
    creator:     'creator_tesim',
    date:        'date_tesim',
    subject:    'subject_tesim', 
    coverage:   'geography_tesim', 
    accrualMethod: 'acquisition_method_tesim',
    dateAccepted: 'date_acquired_tesim',
    description: 'description_tesim'
  )
```

## Adjusting Routes 
`concern :oai_provider, BlacklightOaiProvider::Routes::Provider.new` at the top of the routes.rb file, and `concerns :oai_provider` inside of the resource for the catalog.
