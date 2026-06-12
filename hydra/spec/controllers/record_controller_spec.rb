require 'rails_helper'

describe RecordController, type: :controller do
  around do |example|
    with_routing do |set|
      set.draw do
        get 'record' => 'record#index'  # <- ✅ Optional id param
      end
      example.run
    end
  end
  describe 'GET #index' do
    let(:acda) { double('Acda', id: '123') }

    it 'redirects to /catalog with error if id is nil' do
      allow(Acda).to receive_message_chain(:where, :first).and_return(nil)
      get :index, params: {}   # no id at all
      expect(flash[:error]).to be_present
      expect(response).to redirect_to('/catalog')
    end

    it 'redirects to /catalog with error if id is empty' do
      allow(Acda).to receive_message_chain(:where, :first).and_return(nil)
      get :index, params: { id: '' }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to('/catalog')
    end

    it 'redirects to /catalog with error if no record found' do
      allow(Acda).to receive(:where).and_return([])
      get :index, params: { id: 'notfound' }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to('/catalog')
    end

    it 'redirects to /catalog/:id if record found' do
      allow(Acda).to receive(:where).and_return([acda])
      get :index, params: { id: '123' }
      expect(response).to redirect_to('/catalog/123')
    end

  end
end
