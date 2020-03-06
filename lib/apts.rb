# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'digest/sha1'
require 'uri'

require 'apts/parser'
require 'apts/version'

# Adapted from https://dev.to/fernandezpablo/scrappeando-propiedades-con-python-4cp8

module Apts
  class Error < StandardError; end

  class Main
    class << self
      def get_history
        IO.readlines('seen.txt', chomp: true)
      rescue StandardError
        []
      end

      def notify(posting)
        token = '1014765302:AAG2r4z0sNYCsUB_nKmSVcl71picZDA2gwA'
        chat_id = '332592625'
        open "https://api.telegram.org/bot#{token}/sendMessage?chat_id=#{chat_id}&text=#{posting[:url]}"
      end

      def mark_as_seen(unseen_postings)
        IO.write('seen.txt', unseen_postings.map { |u| u[:id] }.join("\n"), mode: 'a')
      end

      def run
        @history = get_history
        @parsers = [
          Apts::Parser.new('https://www.zonaprop.com.ar', 'a.go-to-posting'),
          Apts::Parser.new('https://www.argenprop.com', 'div.listing__items div.listing__item a'),
          Apts::Parser.new('https://inmuebles.mercadolibre.com.ar', 'li.results-item .rowItem.item a')
        ]
        @urls = %w[
          https://www.zonaprop.com.ar/departamentos-alquiler-capital-federal-2-ambientes-menos-30000-pesos-orden-publicado-descendente.html
          https://www.argenprop.com/departamento-alquiler-localidad-capital-federal-2-ambientes-hasta-30000-pesos-orden-masnuevos
        ].map { |u| URI(u) }

        @urls.each do |url|
          (parser = @parsers.find { |p| p.url.host == url.host }) || raise("No parser found for #{url}")
          html = Nokogiri::HTML(open(url))
          postings = parser.extract_postings html
          seen, unseen = postings.partition { |l| @history.include? l[:id] }

          puts "#{seen.length} seen, #{unseen.length} unseen"

          unseen.each { |u| notify u }
          mark_as_seen unseen
        end
      end
    end
  end
end
