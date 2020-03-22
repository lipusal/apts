# frozen_string_literal: true

require 'dotenv'
require 'open-uri'
require 'digest/sha1'
require 'uri'
require 'logger'
require 'json'

require_relative 'apts/parsers/zonaprop_parser'
require_relative 'apts/parsers/argenprop_parser'
require_relative 'apts/version'
require_relative 'apts/google/drive'

# Adapted from https://dev.to/fernandezpablo/scrappeando-propiedades-con-python-4cp8

module Apts
  class Error < StandardError; end

  class Main
    class << self
      def notify(listing)
        open "https://api.telegram.org/bot#{ENV['TELEGRAM_TOKEN']}/sendMessage?chat_id=#{ENV['CHAT_ID']}&text=#{listing.to_telegram_string}&parse_mode=HTML"
      end

      def run
        Dotenv.load '.env'
        logger = Logger.new STDOUT

        @drive = Apts::Google::Drive.new
        @history = @drive.seen
        logger.debug "Loaded #{@history.length} seen listings"
        # @parsers = [
        #   Apts::Parser.new('https://www.zonaprop.com.ar', 'a.go-to-posting'),
        #   Apts::Parser.new('https://www.argenprop.com', 'div.listing__items div.listing__item a'),
        #   Apts::Parser.new('https://inmuebles.mercadolibre.com.ar', 'li.results-item .rowItem.item a')
        # ]
        @parsers = [
          Apts::Parsers::ZonaPropParser.new(URI('https://www.zonaprop.com.ar/departamentos-alquiler-palermo-belgrano-recoleta-barrio-norte-las-canitas-nunez-villa-crespo-colegiales-2-ambientes-menos-30000-pesos-orden-publicado-descendente.html')),
          Apts::Parsers::ArgenPropParser.new(URI('https://www.argenprop.com/departamento-alquiler-barrio-br-norte-barrio-belgrano-barrio-palermo-barrio-colegiales-barrio-nunez-barrio-villa-crespo-2-ambientes-hasta-30000-pesos-orden-masnuevos')),
        ]
        logger.debug "#{@parsers.length} parsers configured"

        listings = []

        @parsers.each do |parser|
          parser_listings = parser.extract_listings
          seen, unseen = parser_listings.partition { |l| @history.include? l.id }

          logger.info "Extracted #{parser_listings.length} listings from #{parser.url.host}: #{seen.length} seen, #{unseen.length} unseen"
          listings.concat unseen
        end

        logger.info "Extracted #{listings.length} unseen listings in total"
        logger.info "Average score: #{format '%.0f', listings.map(&:score).sum / listings.length}" if listings.any?
        logger.info 'Notifying unseen listings...'
        listings.each { |u| notify u }
        logger.info 'Marking unseens as seen...'
        @drive.mark_as_seen listings

        logger.info 'DONE'
      end
    end
  end
end
