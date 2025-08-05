# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BlacklightRangeLimit::RangeFormComponentDecorator do
  let(:dummy_facet_field) do
    double('FacetField',
      key: 'year',
      search_state: double('SearchState', params_for_search: {
        utf8: '✓',
        page: 2,
        range: { 'year' => { 'begin' => '2000', 'end' => '2020' }, 'other' => { 'begin' => '1900', 'end' => '1950' } },
        q: 'test',
        search_field: 'all_fields',
        extra: 'foo'
      })
    )
  end

  let(:decorator_class) do
    Class.new do
      include BlacklightRangeLimit::RangeFormComponentDecorator
      attr_accessor :facet_field
      def initialize(facet_field)
        @facet_field = facet_field
      end
    end
  end

  subject { decorator_class.new(dummy_facet_field) }

  before do
    allow(Blacklight::HiddenSearchStateComponent).to receive(:new) do |params:|
      double('HiddenSearchStateComponent', params: params)
    end
  end

  describe '#hidden_search_state' do
    it 'removes utf8 and page, and removes this facet from range' do
      hidden = subject.send(:hidden_search_state)
      expect(hidden).to respond_to(:params)
      expect(hidden.params).not_to have_key(:utf8)
      expect(hidden.params).not_to have_key(:page)
      expect(hidden.params[:range]).not_to have_key('year')
    end

    it 'adds dummy search_field if none exists' do
      # Remove search_field from params
      allow(dummy_facet_field).to receive(:search_state).and_return(double(params_for_search: { range: {} }))
      hidden = subject.send(:hidden_search_state)
      expect(hidden.params['search_field']).to eq('dummy_range')
    end

    it 'merges special_params with existing params' do
      hidden = subject.send(:hidden_search_state)
      expect(hidden.params['search_field']).to eq('dummy_range')
      expect(hidden.params[:extra]).to eq('foo')
    end
  end
end
