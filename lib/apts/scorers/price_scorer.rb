# frozen_string_literal: true

require_relative 'scorer'

module Apts
  module Scorers
    # Scores based on price.
    class PriceScorer < Scorer

      def initialize(optimal_start = 18_000, optimal_end = 23_000, max_y = 100, min_x = 15_000, max_x = 30_000)
        @optimal_start = optimal_start
        @optimal_end = optimal_end
        @max_y = max_y
        @min_x = min_x
        @max_x = max_x
      end

      def calc(l)
        price = l.price[:total]
        return @max_y if price >= @optimal_start && price <= @optimal_end

        price < @optimal_start ? calc_lower(price) : calc_upper(price)
      end

      private

      def calc_lower(price)
        slope = (0.0 - @max_y) / (@min_x - @optimal_start)
        intercept = @max_y - slope*@optimal_start

        slope * price + intercept
      end

      def calc_upper(price)
        slope = (0.0 - @max_y) / (@max_x - @optimal_end)
        intercept = @max_y - slope * @optimal_end

        slope * price + intercept
      end
    end
  end
end
