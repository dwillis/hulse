module Hulse
  class CommitteeReport

    attr_reader :congress, :chamber, :title, :number, :committee, :committee_code, :bill, :bill_url, :text, :pdf_url

    def self.fetch(url)
      doc = RestClient.get(url)
      Nokogiri::HTML(doc.body)
    end

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def to_s
      number
    end

    def self.create(url)
      html = fetch(url)
      scrape_page(html)
    end

    def self.scrape_page(html)
      if html.css("td a").detect{|a| a['href'].include?('/committee/')}
        committee =  html.css("td a").detect{|a| a['href'].include?('/committee/')}.text
        committee_code = html.css("td a").detect{|a| a['href'].include?('/committee/')}['href'].split('/').last.upcase
      else
        committee = nil
        committee_code = nil
      end

      if html.css("td a").detect{|a| a['href'].include?('/bill/')}
        bill =  html.css("td a").detect{|a| a['href'].include?('/bill/')}.text
        bill_url = html.css("td a").detect{|a| a['href'].include?('/bill/')}['href']
      else
        bill = nil
        bill_url = nil
      end

      self.new(
        congress: html.css("#report ul li a").first['href'].split('/')[1],
        chamber: html.css("h1").first.text[0] == 'H' ? 'House' : 'Senate',
        number: html.css("h1").first.children[0].text.split(' - ')[0],
        title: html.css("h1").first.children[0].text.split(' - ')[1],
        pdf_url: "https://www.congress.gov" + html.css("#report ul li a").first['href'],
        committee: committee,
        committee_code: committee_code,
        bill: bill,
        bill_url: bill_url,
        text: html.css("pre").text
      )
    end

  end
end
