require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  # Skip index for now due to Solr stubbing complexity
  # describe 'GET #index' do
  #   it 'returns success' do
  #     get :index
  #     expect(response).to have_http_status(:success)
  #   end
  # end

  describe 'GET #about' do
    it 'returns success' do
      get :about
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #contribute' do
    it 'returns success' do
      get :contribute
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #partners' do
    it 'returns success' do
      get :partners
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #policies' do
    it 'returns success' do
      get :policies
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #educationalresources' do
    it 'returns success' do
      get :educationalresources
      expect(response).to have_http_status(:success)
    end
  end
end