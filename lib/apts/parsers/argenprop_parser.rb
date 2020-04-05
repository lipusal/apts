# frozen_string_literal: true
require_relative 'parser'

module Apts
  module Parsers
    class ArgenPropParser < Parser
      attr_reader :url

      def initialize(url)
        @base = URI('https://www.argenprop.com.ar')
        super url, 'div.listing__item'
      end

      private

      def listing_url(l)
        path = l.css('a')[0]['href']
        "#{@base.scheme}://#{@base.host}#{path}"
      end

      def price(l)
        base = l.css('a div.card__monetary-values > p.card__price')[0].text.strip.sub(/^\$\s?/, '').sub(/[.,]/, '').to_i
        expensas = l.css('a div.card__monetary-values > p.card__expenses')[0].text.strip.sub(/^&plus;\s*\$\s?/, '').sub(/\s?expensas$/i, '').sub(/[.,]/, '').to_i rescue 0
        {
          base: base,
          expensas: expensas,
          total: base + expensas
        }
      end

      def size(l)
        data = l.css('a div.card__details-box > p.card__common-data')[0].text.strip
        parsed_total = data.match(/^(\d+)\s?m/)
        total = parsed_total[1].to_i rescue nil
        covered = nil
        {
          covered: covered,
          total: total
        }
      end

      def address(l)
        data = l.css('a div.card__details-box > div.card__location-address-box > .card__address')[0]
        return if data.nil?

        data.text.strip
            .gsub(/[\n\t]/, '')
            .gsub(/\s{2,}/, ' ')
            .sub(/\s+al\s+/i, ' ')
      end
    end
  end
end
