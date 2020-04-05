# frozen_string_literal: true

require_relative 'parser'
require 'uri'

module Apts
  module Parsers
    class MercadoLibreParser < Parser
      attr_reader :url

      def initialize(url)
        @base = URI('https://inmuebles.mercadolibre.com.ar/')
        super url, '#searchResults li.results-item'
      end


      private

      def listing_url(l)
        url = URI(l.css('a.item__info-link')[0]['href'])
        # Drop fragment, as it contains a tracking ID (likely autogenerated) which would defeat our own ID generation
        url = url.to_s.sub("##{url.fragment}", '') unless url.fragment.nil?
        url.to_s
      end

      def price(l)
        base = l.css('div.item__info div.item__price .price__fraction')[0].text.sub(/[.,]/, '').to_i rescue 0
        expensas = 0 # This is not provided in this page. The listing URL should be followed and data can be parsed from there
        {
          base: base,
          expensas: expensas,
          total: base + expensas
        }
      end

      def size(l)
        data = l.css('div.item__info div.item__attrs').text
        parsed_covered = data.match(/^\s*(\d+)\s?m/)
        covered = parsed_covered[1]&.to_i
        total = covered # This is not provided, so we just take covered
        {
          covered: covered,
          total: total
        }
      end

      def location(l)
        data = l.css('div.item__info div.item__title')
        return if data.nil?

        data.text.strip
            .gsub(/ - /, ', ')
            .sub(/\s+al\s+/, ' ')
      end
    end
  end
end
