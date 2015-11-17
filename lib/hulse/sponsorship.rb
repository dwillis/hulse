module Hulse
  class Sponsorship

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.base_url(congress)
      "https://www.congress.gov/sponsors-cosponsors/#{congress.to_i.ordinalize.to_s}-congress/representatives/all"
    end

    def self.fetch(url)
      doc = HTTParty.get(url)
      Nokogiri::HTML(doc.parsed_response)
    end

    def self.totals(congress)
      results = []
      html = fetch(base_url(congress))
      table = (html/:table).first
      (table/:tr)[1..-1].each do |row|
        results << { bioguide_id: (row/:td).first.children.first['href'].split('/').last, member_url: (row/:td).first.children.first['href'], sponsored_bills: (row/:td)[1].text.gsub(' Sponsored','').to_i, cosponsored_bills: (row/:td)[2].text.gsub(' Cosponsored','').to_i}
      end
      results
    end

    def self.member_details(url, congress)
      sponsored_bills = []
      cosponsored_bills = []
      # each page has first 250 results; figure out pagination
      html = fetch(url+'?pageSize=250')
      html.css('ol.results_list li h2').each do |bill|
        bill_num = bill.css('h2').children.first.text
        bill_url = bill.css('h2').children.first['href']
        sponsor_bioguide = bill.css('table tr td').first.children.first['href'].split('/').last
        if sponsor_bioguide == bioguide_id
          sponsored_bills << {bill: bill_num, url: bill_url, sponsor_bioguide: sponsor_bioguide, congress: congress}
        else
          cosponsored_bills << {bill: bill_num, url: bill_url, sponsor_bioguide: sponsor_bioguide, congress: congress}
        end
      end


    end
  end
end
