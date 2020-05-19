# frozen_string_literal: true

require 'dotenv'
require 'open-uri'
require 'uri'
require 'logger'
require 'json'

require_relative 'apts/blacklist'
require_relative 'apts/parsers/zonaprop_parser'
require_relative 'apts/parsers/mercadolibre_parser'
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
        @logger = Logger.new STDOUT

        @blacklist = Apts::Blacklist.new
        @drive = Apts::Google::Drive.new
        @history = @drive.seen
        @logger.debug "Loaded #{@history.length} seen listings"

        @parsers = [
          # ZonaProp <= 5 años
          Apts::Parsers::ZonaPropParser.new(URI('https://www.zonaprop.com.ar/departamentos-alquiler-palermo-belgrano-recoleta-barrio-norte-las-canitas-nunez-villa-crespo-colegiales-2-ambientes-hasta-5-anos-menos-30000-pesos-orden-publicado-descendente.html')),
          # ZonaProp 5 años <= x <= 10 años
          Apts::Parsers::ZonaPropParser.new(URI('https://www.zonaprop.com.ar/departamentos-alquiler-palermo-belgrano-recoleta-barrio-norte-las-canitas-nunez-villa-crespo-colegiales-2-ambientes-entre-5-y-10-anos-menos-30000-pesos-orden-publicado-descendente.html')),
          # ZonaProp 10 años <= x <= 20 años
          Apts::Parsers::ZonaPropParser.new(URI('https://www.zonaprop.com.ar/departamentos-alquiler-palermo-belgrano-recoleta-barrio-norte-las-canitas-nunez-villa-crespo-colegiales-2-ambientes-entre-10-y-20-anos-menos-30000-pesos-orden-publicado-descendente.html')),
          # ZonaProp sin filtro de antigüedad
          Apts::Parsers::ZonaPropParser.new(URI('https://www.zonaprop.com.ar/departamentos-alquiler-palermo-belgrano-recoleta-barrio-norte-las-canitas-nunez-villa-crespo-colegiales-2-ambientes-menos-30000-pesos-orden-publicado-descendente.html')),

          # THE TRAILING / FOR ML IS NECESSARY!
          Apts::Parsers::MercadoLibreParser.new(URI('https://inmuebles.mercadolibre.com.ar/departamentos/alquiler/2-ambientes/capital-federal/barrio-norte-o-belgrano-o-belgrano-barrancas-o-belgrano-c-o-belgrano-chico-o-belgrano-r-o-botanico-o-colegiales-o-las-canitas-o-nunez-o-palermo-o-palermo-chico-o-palermo-hollywood-o-palermo-nuevo-o-palermo-soho-o-palermo-viejo-o-recoleta-o-villa-crespo/')),

          Apts::Parsers::ArgenPropParser.new(URI('https://www.argenprop.com/departamento-alquiler-barrio-br-norte-barrio-belgrano-barrio-palermo-barrio-colegiales-barrio-nunez-barrio-villa-crespo-2-ambientes-hasta-30000-pesos-orden-masnuevos')),
        ]
        @logger.debug "#{@parsers.length} parsers configured"

        # Group listings by host
        grouped_listings = Hash.new { |hash, key| hash[key] = [] }
        @parsers.each do |parser|
          unseen_listings = get_unseen_listings(parser)
          grouped_listings[parser.url.host].concat unseen_listings
          # Add to history so other runs of the same parser don't count
          @history.concat unseen_listings.map(&:id)
        end

        listings = post_process(grouped_listings).values.flatten
        @logger.info "Extracted #{listings.length} unseen listings in total"
        @logger.info "Average score: #{format '%.0f', listings.map(&:score).sum / listings.length}" if listings.any?

        @logger.info 'Notifying unseen listings...'
        listings.each { |u| notify u }

        @logger.info 'Marking unseens as seen...'
        @drive.mark_as_seen listings

        @logger.info 'DONE'
      end

      def get_unseen_listings(parser)
        parser_listings = parser.extract_listings
        # Apply blacklist
        original_size = parser_listings.length
        parser_listings.reject! { |l| @blacklist.blacklisted? l }
        filtered_listings = original_size - parser_listings.length
        @logger.info "Filtered out #{filtered_listings} blacklisted listings" if filtered_listings.positive?

        # Partition by seen
        seen, unseen = parser_listings.partition { |l| @history.include? l.id }

        @logger.info "Extracted #{parser_listings.length} listings from #{parser.url.host}: #{seen.length} seen, #{unseen.length} unseen"
        unseen
      end

      # Remove duplicate entries limit results in each group
      def post_process(grouped_listings)
        max_listings_per_parser = ENV['MAX_LISTINGS_PER_PARSER']&.to_i
        @logger.debug "Limiting to #{max_listings_per_parser} listings per host" unless max_listings_per_parser.nil?
        grouped_listings.transform_values do |entries|
          # Remove duplicates in each group
          result = entries.uniq
          # Limit results if configured to do so
          result = entries.take max_listings_per_parser unless max_listings_per_parser.nil?

          result
        end
      end
    end
  end
end
