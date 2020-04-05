# frozen_string_literal: true

require_relative 'scorers/size_scorer'
require_relative 'scorers/price_scorer'

module Apts
  class Listing
    include Comparable
    attr_reader :id, :url, :price, :expensas, :size, :address

    def initialize(id, url, price:, size:, address:)
      @id = id
      @url = url
      @price = price
      @size = size
      @address = address
    end

    def score
      scores = [
        Apts::Scorers::SizeScorer.new.calc(self),
        Apts::Scorers::PriceScorer.new.calc(self)
      ]
      scores.sum
    end

    def <=>(other)
      score <=> other.score
    end

    def to_s
      "Listing $#{price[:total]}, #{size[:total]}m2, #{url.path} (#{id})"
    end

    def to_telegram_string
      # https://freelancing-gods.com/2017/07/27/friendly-frozen-string-literals.html
      result = String.new "$#{price[:total]}"
      result << ' (expensas = ?)' unless price[:expensas].positive?
      result << ", #{size[:total] || '?'}m2"
      result << ", <b>score: #{format '%.0f', score}</b>"
      result << "%0A#{url}" # %0A = \n
    end

    # https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Lint/ToJSON
    def to_json(*_args)
      {
        url: url,
        price: price,
        size: size
      }
    end
  end
end
