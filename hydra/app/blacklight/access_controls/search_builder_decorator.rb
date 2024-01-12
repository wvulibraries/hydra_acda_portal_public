# frozen_string_literal: true

##
# OVERRIDE blacklight-access_controls v6.0.1
module Blacklight
  module AccessControls
    ##
    # Override Blacklight::AccessControls::SearchBuilder to smooth over conflicting parameter
    # signature for the {#initialize} method.
    module SearchBuilderDecorator
      ##
      # @note When requesting GET `/advanced`, we initialize a
      #       Blacklight::AccessControls::SearchBuilder twice.  One of those times the
      #       initialization comes from Blacklight::AccessControls the other comes from Blacklight.
      #       And each attempts to initialize with a different method signature.  I have provided
      #       links to those different initialization end-points.
      #
      # @see https://github.com/projectblacklight/blacklight-access_controls/blob/bfa3c9cd5a32648cb9739f503afec3b690b15750/lib/blacklight/access_controls/catalog.rb#L20-L22
      # @see https://github.com/projectblacklight/blacklight-access_controls/blob/bfa3c9cd5a32648cb9739f503afec3b690b15750/lib/blacklight/access_controls/search_builder.rb#L23-L31
      # @see https://github.com/projectblacklight/blacklight/blob/f07cc24d64702f9f2700df2d258d5ba797747210/lib/blacklight/search_builder.rb#L20-L39
      def initialize(*args)
        case args.first
        when ActionController::Base
          Rails.logger.debug("#{self.class}##{__method__} with controller as first parameter; caller: #{caller[0]}")
          super
        when Array
          if args.first.all? { |elements| elements.is_a?(Symbol) }
            Rails.logger.debug("#{self.class}##{__method__} with processor_chain as first parameter; caller: #{caller[0]}")
            self.default_processor_chain = args.first
            super(args[1], ability: args[1].current_ability)
          else
            Rails.logger.debug("#{self.class}##{__method__} with an attempt at a processor_chain as first parameter; caller: #{caller[0]}.  Best wishes on debugging.")
            raise RuntimeError, "Expected #{args.first.inspect} to be an array of symbols, which would likely be a default_processor_chain"
          end
        else
          Rails.logger.debug("#{self.class}##{__method__} received with an unknown initial parameter; caller: #{caller[0]}.  Best wishes on debugging.")
          raise RuntimeError, "Expected #{args.first.inspect} to be an Array of symbols or an ActionController::Base, got #{args.first.class}"
        end
      end
    end
  end
end

Blacklight::AccessControls::SearchBuilder.prepend(Blacklight::AccessControls::SearchBuilderDecorator)
