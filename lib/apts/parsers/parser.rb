# frozen_string_literal: true
require 'open-uri'
require 'nokogiri'
require 'digest/sha1'
require_relative '../listing'

module Apts
  module Parsers
    class Parser

      def initialize(url, listings_regex)
        raise ArgumentError, "Invalid host for #{self.class.name}, expected #{@base.host} but got #{url.host}" unless @base.host.include? url.host

        @url = URI(url)
        @listings_regex = listings_regex
      end

      def extract_listings
        html = Nokogiri::HTML(open(@url))
        html.css(@listings_regex).map { |l| to_listing l }
      end

      def to_listing(l)
        Listing.new id(l), URI(listing_url(l)), price: price(l), size: size(l)
      end

      def id(l)
        Digest::SHA1.hexdigest listing_url(l)
      end

      def to_s
        "Parser for #{@url}"
      end
    end
  end
end
