module Hulse
  class Sponsorship

    attr_reader :member_bioguide_id, :bill_number, :bill_url, :sponsor_bioguide_id, :congress, :date, :description

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.create_from_results(sponsorships)
      sponsorships.map{|r| self.new(r)}
    end

    def self.house_url(congress)
      "https://www.congress.gov/sponsors-cosponsors/#{congress.to_i.ordinalize.to_s}-congress/representatives/all"
    end

    def self.senate_url(congress)
      "https://www.congress.gov/sponsors-cosponsors/#{congress.to_i.ordinalize.to_s}-congress/senators/all"
    end

    def self.fetch(url)
      doc = RestClient.get(url)
      Nokogiri::HTML(doc.body)
    end

    def self.totals(congress)
      results = []
      house = fetch(house_url(congress))
      table = house.css('table').first
      table.css('tr')[1..-1].each do |row|
        results << { bioguide_id: row.css('td').first.children.first['href'].split('/').last, member_url: row.css('td').first.children.first['href'], sponsored_bills: row.css('td')[1].text.gsub(' Sponsored','').to_i, cosponsored_bills: row.css('td')[2].text.gsub(' Cosponsored','').to_i}
      end
      senate = fetch(senate_url(congress))
      table = senate.css('table').first
      table.css('tr')[1..-1].each do |row|
        results << { bioguide_id: row.css('td').first.children.first['href'].split('/').last, member_url: row.css('td').first.children.first['href'], sponsored_bills: row.css('td')[1].text.gsub(' Sponsored','').to_i, cosponsored_bills: row.css('td')[2].text.gsub(' Cosponsored','').to_i}
      end
      results
    end

    def self.parse_html(html, bioguide_id, congress)
      sponsorships = []
      html.css('ol.results_list li h2').each do |bill|
        bill_num = bill.children.first.text
        bill_url = bill.children.first['href']
        sponsor_bioguide = bill.next.next.next.next.css('tr td').first.children.first['href'].split('/').last
        if sponsor_bioguide == bioguide_id
          sponsorships << {member_bioguide_id: bioguide_id, bill_number: bill_num, bill_url: bill_url, sponsor_bioguide_id: sponsor_bioguide, congress: congress, description: 'sponsored'}
        else
          sponsorships << {member_bioguide_id: bioguide_id, bill_number: bill_num, bill_url: bill_url, sponsor_bioguide_id: sponsor_bioguide, congress: congress, description: 'cosponsored'}
        end
      end
      sponsorships
    end

    def self.member_details(url, congress)
      html = fetch(url+"?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250")
      return [] if html.css('ol.results_list li h2').empty?
      total = html.css('strong').first.next.text.strip.split('of ').last.to_i
      max_page = (total.to_f/250.0).ceil
      bioguide_id = url.split('/').last
      sponsorships = parse_html(html, bioguide_id, congress)
      if max_page == 2
        doc = RestClient.get(url+"?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{max_page}")
        html = Nokogiri::HTML(doc.body)
        sponsorships << parse_html(html, bioguide_id, congress)
      elsif max_page > 2
        (2..max_page).each do |page|
          doc = RestClient.get(url+"?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{page}")
          html = Nokogiri::HTML(doc.body)
          sponsorships << parse_html(html, bioguide_id, congress)
        end
      end
      create_from_results(sponsorships.flatten)
    end

  end
end
