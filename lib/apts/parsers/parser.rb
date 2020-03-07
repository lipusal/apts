# frozen_string_literal: true
require 'open-uri'
require 'nokogiri'
require_relative '../listing'

module Apts
  module Parsers
    class Parser
      @@base = nil

      def initialize(url, listings_regex)
        raise ArgumentError("Invalid host for #{self.class.name}, expected #{@@base.host} but got #{url.host}") unless @@base.host.include? url.host

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

      # def url(l)
      #   raise NotImplementedError
      # end
      #
      # def score(l)
      #   raise NotImplementedError
      # end
      #
      # def price(l)
      #   raise NotImplementedError
      # end
      #
      # def size(l)
      #   raise NotImplementedError
      # end
      #
      # def location(l)
      #   raise NotImplementedError
      # end

      # def initialize2(url, link_regex, price_regex:, expensas_regex: nil, size_regex:)
      #   @url = URI(url)
      #   @listings_regex = link_regex
      #   @price_regex = price_regex
      #   @expensas_regex = expensas_regex
      #   @size_regex = size_regex
      # end
      #
      # def extract_listings2(html)
      #   html.css(listings_regex)
      #       .map do |link|
      #     href = link['href']
      #     id = Digest::SHA1.hexdigest href
      #     Listing.new id, "#{url}#{href}", self
      #   end
      # end

      def to_s
        "Parser for #{@url}"
      end
    end
  end
end
