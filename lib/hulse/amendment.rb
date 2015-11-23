module Hulse
  class Amendment

    attr_reader :url, :number, :sponsor_url, :sponsor_party, :sponsor_state, :sponsor_bioguide, :offered_date, :latest_action_text, :latest_action_date, :chamber, :sponsor_name

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.create_from_results(results)
      results.map{|r| self.new(r)}
    end

    def self.create_from_result(result)
      self.new(result)
    end

    def self.get_bioguide_party_and_state(row, td)
      begin
        party, state = row.css('td')[td].children.first.children.text.split('[').last.split('-').first(2)
        bioguide = row.css('td')[td].children.first['href'].split('/').last
        [bioguide, party, state]
      rescue
        # some amendments are sponsored by a committee
        [nil, nil, nil]
      end
    end

    def self.get_offered_date(row, td)
      begin
        Date.strptime(row.css('td')[td].children.last.text.strip.split.last.gsub(")",""), "%m/%d/%Y")
      rescue
        row.css('td')[td].children.last.text.strip.split.last.gsub(")","")
      end
    end

    def self.get_latest_action_date(row, td)
      begin
        Date.strptime(row.css('td')[td+1].text.split.first,"%m/%d/%y")
      rescue
        row.css('td')[td+1].text.split.first
      end
    end

    def self.parse_html(html)
      amendments = []
      html.css('ol.results_list li').each do |row|
        headers = row.css('tr').map{|r| r.css('th').text}
        if headers.size == 2
          td = 0
        else
          td = 1
        end
        offered_date = get_offered_date(row, td)
        latest_action_date = get_latest_action_date(row, td)
        bioguide, party, state = get_bioguide_party_and_state(row, td)
        amendments << { url: row.css('h2').first.children.first['href'], number: row.css('h2').first.children.first.text, sponsor_url: row.css('td')[td].children.first['href'],
        sponsor_bioguide: bioguide , sponsor_party: party, sponsor_state: state, sponsor_name: row.css('td')[td].children.first.children.text, offered_date: offered_date, latest_action_text: row.css('td')[td+1].text.strip, latest_action_date: latest_action_date
        }
      end
      amendments
    end

    def self.scrape_amendments(amendments_url)
      amendments = []
      doc = HTTParty.get(amendments_url)
      html = Nokogiri::HTML(doc.parsed_response)
      total = html.css('strong').first.next.text.strip.split('of ').last.to_i
      max_page = (total.to_f/250.0).round
      amendments << parse_html(html)
      (2..max_page).each do |page|
        doc = HTTParty.get(amendments_url+"&page=#{page}")
        html = Nokogiri::HTML(doc.parsed_response)
        amendments << parse_html(html)
      end
      # process other pages
      create_from_results(amendments.flatten)
    end

    def chamber
      number.chars.first == 'H' ? 'House' : 'Senate'
    end


  end
end
