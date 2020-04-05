module Apts
  class Blacklist
    def blacklisted?(listing)
      listing.address.match?(/VERA 0/i)
    end
  end
end
