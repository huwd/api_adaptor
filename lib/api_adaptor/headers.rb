# frozen_string_literal: true

module ApiAdaptor
  class Headers
    class << self
      def set_header(header_name, value)
        header_data[header_name] = value
      end

      def headers
        header_data.reject { |_k, v| (v.nil? || v.empty?) }
      end

      def clear_headers
        Thread.current[:headers] = {}
      end

      private

      def header_data
        Thread.current[:headers] ||= {}
      end
    end
  end
end
