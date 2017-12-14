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

    def self.scrape_page(html)
      self.new(
        congress: html.css("#report ul li a").first['href'].split('/')[1],
        chamber: html.css("h1").first.text.first == 'H' ? 'House' : 'Senate'
        number: html.css("h1").first.children[0].text.split(' - ')[0],
        title: html.css("h1").first.children[0].text.split(' - ')[1],
        pdf_url: "https://www.congress.gov" + html.css("#report ul li a").first['href'],
        committee: html.css("td a")[1].text,
        committee_code: html.css("td a")[1]['href'].split('/').last.upcase,
        bill: html.css("td a").first.text,
        bill_url: html.css("td a").first['href'],
        text: html.css("pre")
      )
    end

  end
end
