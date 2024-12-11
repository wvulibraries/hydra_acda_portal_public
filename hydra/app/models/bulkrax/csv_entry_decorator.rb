# frozen_string_literal: true

# OVERRIDE Bulkrax v8.3.0 to NOT strip out `:` (colon) and '/' (slash) characters from headers

module Bulkrax
  module CsvEntryDecorator
    extend ActiveSupport::Concern

    class_methods do
      def read_data(path)
        raise StandardError, 'CSV path empty' if path.blank?
        options = {
          headers: true,
          header_converters: ->(h) { h.to_s.gsub(/[^\w\d\.\-:\/ ]+/, '').strip.to_sym },
          encoding: 'utf-8'
        }.merge(csv_read_data_options)

        results = CSV.read(path, **options)
        csv_wrapper_class.new(results)
      end
    end
  end
end

Bulkrax::CsvEntry.prepend(Bulkrax::CsvEntryDecorator)
# This is a workaround, the bulkrax initializer is wrapped in a to_prepare and Bulkrax.default_work_type
# is not set by the time it is called so it is nil.  For now we can set it here.  The bigger issue we'd
# need to look at is why we need to wrap the bulkrax initializer in a to_prepare.
Bulkrax::CsvEntry.class_attribute :default_work_type, default: 'Acda'
