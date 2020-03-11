# frozen_string_literal: true

require_relative 'scorers/size_scorer'
require_relative 'scorers/price_scorer'

module Apts
  class Listing
    attr_reader :id, :url, :price, :expensas, :size

    def initialize(id, url, price:, size:)
      @id = id
      @url = url
      @price = price
      @size = size
    end

    def score
      scores = [
        Apts::Scorers::SizeScorer.new.calc(self),
        Apts::Scorers::PriceScorer.new.calc(self)
      ]
      scores.sum
    end

    def to_s
      "Listing $#{price[:total]}, #{size[:total]}m2, #{url.path} (#{id})"
    end

    def to_telegram_string
      # %0A = \n
      "$#{price[:total]}, #{size[:total]}m2, <b>score: #{format '%.0f', score}</b>%0A#{url}"
    end

    # https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Lint/ToJSON
    def to_json(*_args)
      {
        url: url,
        basePrice: price[:base],
        expensas: price[:expensas],
        totalPrice: price[:total],
        totalSize: size[:total]
      }
    end
  end
end
