module Apts
  class Parser
    attr_accessor :url, :link_regex

    def initialize(url, link_regex)
      @url = URI(url)
      @link_regex = link_regex
    end

    def extract_postings(html)
      html.css(link_regex)
          .map do |link|
        href = link['href']
        id = Digest::SHA1.hexdigest href
        { id: id, url: "#{url}#{href}" }
      end
    end

    def score
      100
      # TODO
    end

    def to_s
      "Parser for #{url}"
    end
  end
end
