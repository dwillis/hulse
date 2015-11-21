module Hulse
  class Bill

    attr_reader :url, :number, :title, :sponsor_url, :sponsor_bioguide, :sponsor_party, :sponsor_state, :introduced_date, :bill_type, :committees,
    :latest_action_text, :latest_action_date, :status, :actions_url, :chamber

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.fetch(congress, page=1)
      doc = HTTParty.get("https://www.congress.gov/legislation?q=%7B%22congress%22%3A%22#{congress}%22%7D&pageSize=250&page=#{page}&%2C%22type%22%3A%5B%22bills%22%2C%22resolutions%22%2C%22joint-resolutions%22%2C%22concurrent-resolutions%22%5D%7D")
      Nokogiri::HTML(doc.parsed_response)
    end

    def self.create_from_results(results)
      bills = []
      bills << results.map{|r| self.new(r)}
    end

    def self.create_from_result(result)
      self.new(result)
    end

    def self.scrape_page(html)
      results = []
      html.css('ol.results_list h2').each do |bill|
        next if bill.children.first.children.text.include?('Amdt')
        next if bill.next.next.text == 'Reserved for the Speaker.'
        next if bill.next.next.text == 'Reserved for the Minority Leader.'
        puts bill.children.first.children.text
        table = bill.next.next.next.next
        cmtes = get_committees(table)
        latest_action = get_latest_action(table)
        status_tracker = get_status_tracker(table)
        party, state = get_party_and_state(table)
        sponsor_url, sponsor_bioguide = get_sponsor(table)
        introduced_date = get_introduced_date(table)
        latest_action_text, latest_action_date = get_latest_action(table)
        results << {url: bill.children.first['href'], number: bill.children.first.children.text, title: bill.next.next.text,
        sponsor_url: sponsor_url, sponsor_bioguide: sponsor_bioguide, sponsor_party: party, sponsor_state: state.gsub(']',''),
        introduced_date: introduced_date, bill_type: Hulse::Utils.bill_type(bill.children.first.children.text)['title'],
        committees: cmtes, latest_action_text: latest_action, latest_action_date: latest_action_date, status: status_tracker}
      end
      create_from_results(results)
    end

    def self.get_committees(table)
      committees = table.css('tr').detect{|row| row.children[1].text == 'Committees:'}
      if committees
        cmtes = committees.children[3].text.strip
      else
        cmtes = nil
      end
      cmtes
    end

    def self.get_introduced_date(table)
      Date.strptime(table.css('tr').first.children[3].children.last.text.strip.split.last.gsub(')',''), '%m/%d/%Y')
    end

    def self.get_sponsor(table)
      url = table.css('tr').first.children[3].children.first['href']
      bioguide_id = table.css('tr').first.children[3].children.first['href'].split('/').last
      [url, bioguide_id]
    end

    def self.get_latest_action(table)
      text = table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split("(").first.strip
      date = Date.strptime(table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split.first, '%m/%d/%Y')
      [text, date]
    end

    def self.get_status_tracker(table)
      tr = table.css('tr').detect{|row| row.children[1].text == 'Tracker:'}
      tr.children[3].children.first.text.gsub('This bill has the status','').strip
    end

    def self.get_party_and_state(table)
      table.css('tr').first.children[3].children.first.text.split('[').last.split('-').first(2)
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

    def self.scrape_bill(url)
      doc = HTTParty.get(url)
      html = Nokogiri::HTML(doc.parsed_response)
      bill_number, title = html.css('h1').first.children.first.text.split(' - ')
      table = html.css('table.standard01')
      cmtes = get_committees(table)
      latest_action = get_latest_action(table)
      status_tracker = html.css('p.hide_fromsighted').children.first.text.gsub('This bill has the status','').strip
      party, state = get_party_and_state(table)
      sponsor_url, sponsor_bioguide = get_sponsor(table)
      introduced_date = get_introduced_date(table)
      latest_action_text, latest_action_date = get_latest_action(table)
      create_from_result({url: url, number: bill_number, title: title, sponsor_url: sponsor_url, sponsor_bioguide: sponsor_bioguide,
      sponsor_party: party, sponsor_state: state.gsub(']',''), introduced_date: introduced_date, bill_type: Hulse::Utils.bill_type(bill_number)['title'],
      committees: cmtes, latest_action_text: latest_action, latest_action_date: latest_action_date, status: status_tracker})
    end

    def chamber
      number.chars.first == 'H' ? 'House' : 'Senate'
    end

    def actions_url
      url + '/all-actions'
    end

    def actions
      actions = []
      doc = HTTParty.get(actions_url)
      html = Nokogiri::HTML(doc.parsed_response)
      table = html.css("table.item_table")
      ch = true if table.css('tr')[0].children[3].text == 'Chamber'
      table.css('tr')[1..-1].each do |row|
        if row.css('td').last.children.detect{|r| r.text.strip.include?('Type of Action')}.nil?
          action_type = nil
          action_by = nil
        else
          action_type = row.css('td').last.children.detect{|r| r.text.strip.include?('Type of Action')}.children[0].text.strip.split("Type of Action: ").last
          action_by = row.css('td').last.children.detect{|r| r.text.strip.include?('Action By')}.children[2].text.strip.split("Action By: ").last
        end
        if ch
          actions << {date: Date.strptime(row.css('td').first.text, "%m/%d/%Y"), chamber: row.css('td')[1].text, action: row.css('td').last.children.first.text.strip,
            action_type: action_type, action_by: action_by
          }
        else
          actions << {date: Date.strptime(row.css('td').first.text, "%m/%d/%Y"), chamber: chamber, action: row.css('td').last.children.first.text.strip,
            action_type: row.css('td').last.children[3].children.first.text.strip.split("Type of Action: ").last,
            action_by: row.css('td').last.children[3].children.last.text.strip.split("Action By: ").last
          }
        end
      end
      actions
    end

    def related_bills_url
      url + '/related-bills'
    end

    def related_bills
      related_bills = []
      doc = HTTParty.get(related_bills_url)
      html = Nokogiri::HTML(doc.parsed_response)
      table = html.css("table.item_table.relatedBills")
      return [] if table.css('tr')[1..-1].nil?
      table.css('tr')[1..-1].each do |row|
        next if row.css('td').first.children[1].nil?
        related_bills << {bill_number: row.css('td').first.children[1].text, title: row.css('td')[1].text,
          relationship: row.css('td')[2].text, identified_by: row.css('td')[3].text, latest_action_text: row.css('td')[4].text
        }
      end
      related_bills
    end

    def amendments_url
      url + '/amendments?pageSize=250'
    end

    def amendments
      Amendment.scrape_amendments(amendments_url)
    end




  end
end
