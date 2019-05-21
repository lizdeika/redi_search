# frozen_string_literal: true

module RediSearch
  class Search
    class Term
      def initialize(term, **options)
        @term = term
        @options = options

        validate_options
      end

      def to_s
        if @term.is_a? Range
          stringify_range
        else
          stringify_query
        end
      end

      private

      attr_accessor :term, :options

      def fuzziness
        @fuzziness ||= options[:fuzziness].to_i
      end

      def optional_operator
        return unless options[:optional]

        "~"
      end

      def prefix_operator
        return unless options[:prefix]

        "*"
      end

      def stringify_query
        @term.to_s.
          tr("`", "\`").
          yield_self { |str| "#{'%' * fuzziness}#{str}#{'%' * fuzziness}" }.
          yield_self { |str| "#{optional_operator}#{str}" }.
          yield_self { |str| "#{str}#{prefix_operator}" }.
          yield_self { |str| "`#{str}`" }
      end

      def stringify_range
        first, last = @term.first, @term.last
        first = "-inf" if first == -Float::INFINITY
        last = "+inf" if last == Float::INFINITY

        "[#{first} #{last}]"
      end

      def validate_options
        unsupported_options =
          (options.keys.map(&:to_s) - %w(fuzziness optional prefix)).join(", ")

        if unsupported_options.present?
          raise(ArgumentError,
                "#{unsupported_options} are unsupported term options")
        end

        raise(ArgumentError, "fuzziness can only be between 0 and 3") if
          fuzziness.negative? || fuzziness > 3
      end
    end
  end
end
