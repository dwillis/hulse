module Hulse
  class Nomination

    attr_reader :id, :date, :committee, :url, :text

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.fetch(congress, page=1)
      doc = HTTParty.get("https://www.congress.gov/nominations?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{page}")
      html = Nokogiri::HTML(doc.parsed_response)
    end

    def self.scrape_congress(congress)
      results = []
      html = fetch(congress)
      total_noms = html.css('strong').first.next.text.strip.split('of ').last.gsub(',','').to_i
      pages = (total_noms.to_f/250.0).ceil
      results << scrape_page(html)
      (2..pages).each do |page|
        html = fetch(congress, page)
        results << scrape_page(html)
      end
      results.flatten
    end

    def self.create_from_results(results)
      results.map{|r| self.new(r)}
    end

    def self.create_from_result(result)
      self.new(result)
    end

    def self.scrape_page(html)
      results = []
      html.css('ol.results_list h2').each do |nom|
        table = nom.next.next
        raw_title = nom.children[2].text.strip.split(')').last.encode(Encoding.find('ASCII'), :invalid => :replace, :undef => :replace, :replace => '').strip.split('  ')
        if raw_title.size > 1
          name = raw_title.first
          agency = raw_title.last
        else
          name = nil
          agency = raw_title.first
        end
        results << {
          url: nom.children[1]['href'], number: nom.children[1].children.first.text,
          name: name,
          agency: agency,
          description: table.css('tr').detect{|row| row.children[1].text == 'Description:'}.children[3].text.strip,
          date_received: Date.strptime(table.css('tr').detect{|row| row.children[1].text == 'Date Received from President:'}.children[3].text.strip, '%m/%d/%Y'),
          committee: table.css('tr').detect{|row| row.children[1].text == 'Committee:'}.children[3].text.strip,
          latest_action_text: table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split("(").first.strip.split('-').last.strip,
          latest_action_date: Date.strptime(table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split("(").first.strip.split('-').first.strip, '%m/%d/%Y')
        }
      end
      create_from_results(results)
    end

  end
end
