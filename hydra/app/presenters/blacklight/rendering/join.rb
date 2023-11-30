module Blacklight
  module Rendering
    class Join < AbstractStep
      def render
        options = config.separator_options || {}
        next_step(values.map { |x| html_decode(x) }.join(', '))
      end

      private

      def html_decode(args)
        args.gsub('&lt;', '<').gsub('&gt;', '>')
      end

      def html_escape(*args)
        ERB::Util.html_escape(*args)
      end
    end
  end
end