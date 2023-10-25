Rails.application.routes.draw do
  mount Qa::Engine => '/qa'

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Bulkrax::Engine, at: '/'
  concern :oai_provider, BlacklightOaiProvider::Routes.new
  
  # images
  get 'image/:id'  => 'image_viewer#index'
  get 'thumb/:id'  => 'image_viewer#thumb'

  get 'audio/:id' => 'audio_player#index'
  get 'video/:id' => 'video_player#index'
  get 'pdf/:id' => 'pdf_viewer#index'

  # pages
  get '/about' => 'catalog#about'
  get '/contribute' => 'catalog#contribute'
  get '/partners' => 'catalog#partners'
  get '/policies' => 'catalog#policies'
  get '/contributingcollections' => 'catalog#contributingcollections'

  # featured
  get '/featured' => 'featured#index'
  
  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'

  root to: 'catalog#index'
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :oai_provider
    concerns :searchable
    concerns :range_searchable

  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :acda, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  mount Sidekiq::Web => '/sidekiq'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end