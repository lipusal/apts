# frozen_string_literal: true

require 'dotenv'
require 'open-uri'
require 'nokogiri'
require 'digest/sha1'
require 'uri'
require 'logger'

require 'apts/parser'
require 'apts/version'

# Adapted from https://dev.to/fernandezpablo/scrappeando-propiedades-con-python-4cp8

module Apts
  class Error < StandardError; end

  class Main
    class << self
      def get_history(history_file)
        IO.readlines(history_file, chomp: true)
      rescue StandardError
        []
      end

      def notify(posting)
        open "https://api.telegram.org/bot#{ENV['TELEGRAM_TOKEN']}/sendMessage?chat_id=#{ENV['CHAT_ID']}&text=#{posting[:url]}"
      end

      def mark_as_seen(unseen_postings, file)
        return if unseen_postings.empty?

        content = unseen_postings.map { |u| u[:id] }.join("\n") << "\n"
        file.write content
        file.flush
      end

      def run
        Dotenv.load '.env'
        logger = Logger.new STDOUT

        @history_file = File.open 'seen.txt', 'a+'
        @history = get_history @history_file
        logger.debug "Loaded #{@history.length} seen postings"
        @parsers = [
          Apts::Parser.new('https://www.zonaprop.com.ar', 'a.go-to-posting'),
          Apts::Parser.new('https://www.argenprop.com', 'div.listing__items div.listing__item a'),
          Apts::Parser.new('https://inmuebles.mercadolibre.com.ar', 'li.results-item .rowItem.item a')
        ]
        @urls = %w[
          https://www.zonaprop.com.ar/departamentos-alquiler-capital-federal-2-ambientes-menos-30000-pesos-orden-publicado-descendente.html
          https://www.argenprop.com/departamento-alquiler-localidad-capital-federal-2-ambientes-hasta-30000-pesos-orden-masnuevos
        ].map { |u| URI(u) }

        logger.debug "#{@urls.length} URLs configured"

        @urls.each_with_index do |url, i|
          logger.info "Extracting postings from #{url.host}..."
          (parser = @parsers.find { |p| p.url.host == url.host }) || raise("No parser found for #{url}")
          html = Nokogiri::HTML(open(url))
          postings = parser.extract_postings html
          logger.debug "Extracted #{postings.length} postings"
          seen, unseen = postings.partition { |l| @history.include? l[:id] }

          logger.info "Postings: #{seen.length} seen, #{unseen.length} unseen"
          logger.info 'Notifying unseen postings...'
          unseen.each { |u| notify u }
          logger.info 'Marking unseens as seen'
          mark_as_seen unseen, @history_file
        end

        logger.info "DONE"
      end
    end
  end
end
