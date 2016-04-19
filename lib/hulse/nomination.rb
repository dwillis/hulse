# encoding: utf-8
module Hulse
  class Nomination

    attr_reader :id, :date, :committee, :url, :text, :actions, :agency, :description, :date_received, :latest_action_text, :latest_action_date, :status

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
        latest_action_text = table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split("(").first.strip.split('-').last.strip
        if latest_action_text.include?("Confirmed")
          status = 'Confirmed'
        elsif latest_action_text.include?("withdrawal of nomination")
          status = "Withdrawn"
        else
          status = 'Pending'
        end
        results << {
          url: nom.children[1]['href'],
          id: nom.children[1].children.first.text,
          name: name,
          agency: agency,
          description: table.css('tr').detect{|row| row.children[1].text == 'Description:'}.children[3].text.strip,
          date_received: Date.strptime(table.css('tr').detect{|row| row.children[1].text == 'Date Received from President:'}.children[3].text.strip, '%m/%d/%Y'),
          committee: table.css('tr').detect{|row| row.children[1].text == 'Committee:'}.children[3].text.strip,
          latest_action_text: latest_action_text,
          latest_action_date: Date.strptime(table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split("(").first.strip.split('-').first.strip, '%m/%d/%Y'),
          status: status
        }
      end
      create_from_results(results)
    end

    def self.scrape_nomination(url)
      actions = []
      doc = HTTParty.get(url)
      html = Nokogiri::HTML(doc.parsed_response)
      splitter = html.css('h1').first.children.first.text.unicode_normalize.split[1]
      nom_number, name, agency = html.css('h1').first.children.first.text.unicode_normalize.split(splitter)
      c = html.css('h2').detect{|h| h.text == 'Committee'}
      committee = c.next.next.text.strip if c
      d = html.css('h2').detect{|h| h.text == 'Description'}
      description = d.next.next.text.strip if d
      dr = html.css('h2').detect{|h| h.text == 'Date Received from President'}
      date_received = Date.strptime(dr.next.next.text.strip, '%m/%d/%Y') if dr
      la = html.css('h2').detect{|h| h.text == 'Latest Action'}
      latest_action_text = la.next.next.text.strip if la
      if latest_action_text.include?("Confirmed")
        status = 'Confirmed'
      elsif latest_action_text.include?("withdrawal of nomination")
        status = "Withdrawn"
      else
        status = 'Pending'
      end

      table = html.css('table.item_table')
      table.css('tr')[1..-1].each do |row|
        actions << {date: Date.strptime(row.css('td').first.text, "%m/%d/%Y"), action: row.css('td').last.children.first.text.strip}
      end
      result = {id: nom_number.strip, name: name.strip, agency: agency.strip, description: description, committee: committee, date_received: date_received, latest_action_text: latest_action_text, status: status, actions: actions}
      create_from_result(result)
    end
  end
end
