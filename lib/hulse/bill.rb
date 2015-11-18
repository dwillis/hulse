module Hulse
  class Bill


    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.fetch(congress, page=1)
      doc = HTTParty.get("https://www.congress.gov/legislation?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{page}&%2C%22type%22%3A%5B%22bills%22%2C%22resolutions%22%2C%22joint-resolutions%22%2C%22concurrent-resolutions%22%5D%7D")
      Nokogiri::HTML(doc.parsed_response)
    end

    def self.scrape_page(html)
      results = []
      html.css('ol.results_list h2').each do |bill|
        next if bill.children.first.children.text.include?('Amdt')
        next if bill.next.next.text == 'Reserved for the Speaker.'
        next if bill.next.next.text == 'Reserved for the Minority Leader.'
        puts bill.children.first.children.text
        table = bill.next.next.next.next
        latest_action = table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}
        party, state = table.css('tr').first.children[3].children.first.text.split('[').last.split('-').first(2)
        results << {url: bill.children.first['href'], number: bill.children.first.children.text, title: bill.next.next.text,
        sponsor_url: table.css('tr').first.children[3].children.first['href'], sponsor_bioguide: table.css('tr').first.children[3].children.first['href'].split('/').last,
        party: party, state: state, introduced: table.css('tr').first.children[3].children.last.text.strip.split.last,
        committees: table.css('tr')[1].children[3].text.strip, latest_action_text: latest_action.children[3].children.first.text, latest_action_date: latest_action.children[3].children.first.text.split.first }
      end
      results
    end

    def self.scrape_congress(congress)
      results = []
      html = fetch(congress)
      total_bills = html.css('strong').first.next.text.strip.split('of ').last.gsub(',','').to_i
      pages = (total_bills.to_f/250.0).round
      results << scrape_page(html)
      (1..pages).each do |page|
        html = fetch(congress, page)
        results << scrape_page(html)
      end
      results.flatten
    end


  end
end
