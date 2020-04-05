module Apts
  class Blacklist
    def blacklisted?(listing)
      listing.address.upcase == 'VERA 0'
    end
  end
end
