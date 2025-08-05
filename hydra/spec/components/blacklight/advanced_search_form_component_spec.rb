# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Blacklight::AdvancedSearchFormComponent, type: :component do
  let(:response) { double('response', aggregations: {}) }
  let(:helpers) { double('helpers').as_null_object }
  let(:blacklight_config) do
    double('Blacklight::Configuration',
      search_fields: {
        'title' => double('Field', key: 'title', display_label: ->(_){'Title'}, include_in_advanced_search: true),
        'author' => double('Field', key: 'author', display_label: ->(_){'Author'}, include_in_advanced_search: true),
        'subject' => double('Field', key: 'subject', display_label: ->(_){'Subject'}, include_in_advanced_search: true),
        'date' => double('Field', key: 'date', display_label: ->(_){'Date'}, include_in_advanced_search: true),
        'other' => double('Field', key: 'other', display_label: ->(_){'Other'}, include_in_advanced_search: true)
      },
      sort_fields: {
        'relevance' => double('SortField', key: 'relevance', include_in_advanced_search: true),
        'date' => double('SortField', key: 'date', include_in_advanced_search: true)
      },
      facet_fields: {}
    )
  end
  let(:default_args) { { response: response, url: '/', params: {} } }

  before do
    allow_any_instance_of(described_class).to receive(:helpers).and_return(helpers)
    allow_any_instance_of(described_class).to receive(:blacklight_config).and_return(blacklight_config)
    allow(helpers).to receive(:t).and_return('label')
    allow(helpers).to receive(:label_tag).and_return('<label></label>'.html_safe)
    allow(helpers).to receive(:select_tag).and_return('<select></select>'.html_safe)
    allow(helpers).to receive(:options_for_select).and_return('<option></option>'.html_safe)
    allow(helpers).to receive(:params).and_return({})
    allow(helpers).to receive(:content_tag) { |*_, &block| block ? block.call : '' }
    allow(helpers).to receive(:fields_for) { |*_, &block| block ? block.call(double('f', label: '', hidden_field: '', text_field: '')) : '' }
    allow(helpers).to receive(:render_hash_as_hidden_fields).and_return('')
    allow(helpers).to receive(:sort_field_label).and_return('Relevance')
    allow(helpers).to receive(:search_state).and_return(double(params_for_search: {}, reset: double, except: {}))
  end

  it 'can be instantiated with required args' do
    expect { described_class.new(**default_args) }.not_to raise_error
  end

  it 'calls before_render and initializes controls' do
    comp = described_class.new(**default_args)
    allow(comp).to receive(:render).and_return(nil)
    expect(comp).to receive(:initialize_primary_search_field_controls).and_call_original
    expect(comp).to receive(:initialize_secondary_search_field_controls).and_call_original
    expect(comp).to receive(:initialize_search_filter_controls).and_call_original
    expect(comp).to receive(:initialize_constraints).and_call_original
    comp.before_render
  end

  it 'returns nil for sort_fields_select if no sort fields' do
    comp = described_class.new(**default_args)
    allow(blacklight_config).to receive(:sort_fields).and_return({})
    expect(comp.sort_fields_select).to be_nil
  end

  it 'returns select_tag for qa_options' do
    comp = described_class.new(**default_args)
    allow(comp).to receive(:options_for_qa_select).and_return([['A','A']])
    expect(comp.send(:qa_options, 'title')).to include('select')
  end

  it 'returns correct search_fields and sort_fields' do
    comp = described_class.new(**default_args)
    expect(comp.send(:search_fields).keys).to include('title','author','subject','date','other')
    expect(comp.send(:sort_fields).keys).to include('relevance','date')
  end

  it 'returns only first 4 for primary_search_fields_for' do
    comp = described_class.new(**default_args)
    expect(comp.send(:primary_search_fields_for, blacklight_config.search_fields).length).to eq(4)
  end

  it 'returns remaining for secondary_search_fields_for' do
    comp = described_class.new(**default_args)
    expect(comp.send(:secondary_search_fields_for, blacklight_config.search_fields).length).to eq(1)
  end

  it 'detects local authority' do
    comp = described_class.new(**default_args)
    stub_const('Qa::Authorities::Local', double(names: ['subjects','authors']))
    expect(comp.send(:local_authority?, 'subjects')).to be true
    expect(comp.send(:local_authority?, 'subject')).to be true
    expect(comp.send(:local_authority?, 'title')).to be false
  end

  it 'fetches service for key' do
    stub_const('TitleService', Class.new)
    comp = described_class.new(**default_args)
    expect(comp.send(:fetch_service_for, 'title')).to eq(TitleService)
  end

  it 'options_for_qa_select tries select_all_options, select_options, and fallback' do
    service = double('Service', select_all_options: ['A'], select_options: ['B'])
    comp = described_class.new(**default_args)
    allow(comp).to receive(:fetch_service_for).and_return(service)
    expect(comp.send(:options_for_qa_select, 'title')).to eq(['A'])
    service2 = double('Service', select_options: ['B'])
    allow(comp).to receive(:fetch_service_for).and_return(service2)
    expect(comp.send(:options_for_qa_select, 'title')).to eq(['B'])
    service3 = Class.new { def self.new; self; end; def self.select_all_options; ['C']; end }
    allow(comp).to receive(:fetch_service_for).and_return(service3)
    expect(comp.send(:options_for_qa_select, 'title')).to eq(['C'])
  end
end
