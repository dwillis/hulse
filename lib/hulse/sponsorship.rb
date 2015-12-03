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

    def self.parse_html(html, bioguide_id, congress)
      sponsored_bills = []
      cosponsored_bills = []
      html.css('ol.results_list li h2').each do |bill|
        bill_num = bill.children.first.text
        bill_url = bill.children.first['href']
        sponsor_bioguide = bill.next.next.next.next.css('tr td').first.children.first['href'].split('/').last
        if sponsor_bioguide == bioguide_id
          sponsored_bills << {bill: bill_num, url: bill_url, sponsor_bioguide: sponsor_bioguide, congress: congress}
        else
          cosponsored_bills << {bill: bill_num, url: bill_url, sponsor_bioguide: sponsor_bioguide, congress: congress}
        end
      end
      [sponsored_bills, cosponsored_bills]
    end

    def self.member_details(url, congress)
      sponsored_bills = []
      cosponsored_bills = []
      # each page has first 250 results; figure out pagination
      html = fetch(url+"?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250")
      return [] if html.css('ol.results_list li h2').empty?
      total = html.css('strong').first.next.text.strip.split('of ').last.to_i
      max_page = (total.to_f/250.0).ceil
      bioguide_id = url.split('/').last
      sp, csp = parse_html(html, bioguide_id, congress)
      sponsored_bills << sp
      cosponsored_bills << csp
      if max_page == 2
        doc = HTTParty.get(url+"?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{max_page}")
        html = Nokogiri::HTML(doc.parsed_response)
        sp, csp = parse_html(html, bioguide_id, congress)
        sponsored_bills << sp
        cosponsored_bills << csp
      elsif max_page > 2
        (2..max_page).each do |page|
          doc = HTTParty.get(url+"?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{page}")
          html = Nokogiri::HTML(doc.parsed_response)
          sp, csp = parse_html(html, bioguide_id, congress)
          sponsored_bills << sp
          cosponsored_bills << csp
        end
      end
      [sponsored_bills.flatten, cosponsored_bills.flatten]
    end
  end
end
