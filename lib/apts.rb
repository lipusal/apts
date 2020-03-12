# frozen_string_literal: true

require 'dotenv'
require 'open-uri'
require 'digest/sha1'
require 'uri'
require 'logger'
require 'json'

require_relative 'apts/parsers/zonaprop_parser'
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

      def record(listing)
        `curl --silent -X POST -H 'Content-Type:application/json' https://maker.ifttt.com/trigger/apt_found/with/key/#{ENV['IFTTT_KEY']} -d #{JSON.generate(listing)}`
      end

      def mark_as_seen(unseen_listings, file)
        return if unseen_listings.empty?

        content = unseen_listings.map(&:id).join("\n") << "\n"
        file.write content
        file.flush
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
          Apts::Parsers::ZonaPropParser.new(URI('https://www.zonaprop.com.ar/departamentos-alquiler-capital-federal-2-ambientes-menos-30000-pesos-orden-publicado-descendente.html')),
        ]

        logger.debug "#{@parsers.length} parsers configured"
        @parsers.each do |parser|
          logger.info "Extracting listings from #{parser.url.host}..."
          listings = parser.extract_listings
          logger.debug "Extracted #{listings.length} listings"
          seen, unseen = listings.partition { |l| @history.include? l.id }

          logger.info "Listings: #{seen.length} seen, #{unseen.length} unseen"
          puts "Average score for unseen: #{format '%.0f', unseen.map(&:score).sum / unseen.length}" if unseen.any?
          logger.info 'Notifying unseen listings...'
          unseen.each { |u| notify u }
          logger.info 'Marking unseens as seen'
          @drive.mark_as_seen unseen
        end

        logger.info "DONE"
      end
    end
  end
end
