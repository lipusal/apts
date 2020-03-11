require_relative 'scorer'

module Apts
  module Scorers
    # This class calculates a score based on size. It is based on a parabola generated in https://www.desmos.com/calculator/htfdxbgqdt
    # max_x => h, max_y => k
    class SizeScorer < Scorer
      attr_reader :max_x, :max_y

      def initialize(max_x = 50.0, max_y = 1.0, p = -60.0)
        @max_x = max_x
        @max_y = max_y
        @p = p
      end

      def calc(l)
        ((l.size[:total] - @max_x)**2 / (4 * @p) + @max_y) * 100
      end
    end
  end
end
