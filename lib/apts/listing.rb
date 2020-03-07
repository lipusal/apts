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
      100
    end

    def to_s
      "Listing $#{price[:total]}, #{size[:total]}m2, #{url.path} (#{id})"
    end

    def to_telegram_string
      # %0A = \n
      "$#{price[:total]}, #{size[:total]}m2%0A#{url}"
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
