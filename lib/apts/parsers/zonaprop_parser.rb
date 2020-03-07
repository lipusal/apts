# frozen_string_literal: true
require_relative 'parser'

module Apts
  module Parsers
    class ZonaPropParser < Parser
      attr_reader :url
      @@base = URI('https://www.zonaprop.com.ar')

      def initialize(url)
        super url, 'div.posting-card'
      end


      private

      def listing_url(l)
        path = l.css('a.go-to-posting')[0]['href']
        "#{@@base.scheme}://#{@@base.host}#{path}"
      end

      def score(l)
        raise NotImplementedError
      end

      def price(l)
        base = l.css('div.posting-price > div.prices > span.first-price')[0]['data-price'].sub(/^[$\s]*/, '').sub(/[.,]/, '').to_i rescue 0
        expensas = l.css('div.posting-price > span.expenses')[0].text.sub(/^[+$\s]*/, '').sub(/\s?Expensas$/i, '').sub(/[.,]/, '').to_i rescue 0
        {
          base: base,
          expensas: expensas,
          total: base + expensas
        }
      end

      def size(l)
        data = l.css('ul.main-features > li > b').map(&:text)
        total = data.find { |e| e.match?(/\d+.*totales/i) }.split(' ')[0].to_i
        covered = data.find { |e| e.match?(/\d+.*cubiertos/i) }.split(' ')[0].to_i rescue 0
        {
          covered: covered,
          total: total
        }
      end

      def location(l)
        data = l.css('span.posting-location')
        "#{data.text.strip}#{data.css('span').text}"
      end
    end
  end
end
