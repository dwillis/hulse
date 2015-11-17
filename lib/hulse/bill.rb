module Hulse
  class Bill

    def self.fetch(congress, page=1)
      doc = HTTParty.get("https://www.congress.gov/legislation?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{page}")
      Nokogiri::HTML(doc.parsed_response)
    end


  end
end
