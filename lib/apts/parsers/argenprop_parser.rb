# frozen_string_literal: true
require_relative 'parser'

module Apts
  module Parsers
    class ArgenPropParser < Parser
      @@base = URI('https://www.argenprop.com.ar')

      def initialize(url)
        super url, 'a.go-to-posting'
      end


      private

      def score
        raise NotImplementedError
      end

      def price
        raise NotImplementedError
      end

      def size
        raise NotImplementedError
      end

      def location
        raise NotImplementedError
      end
    end
  end
end
