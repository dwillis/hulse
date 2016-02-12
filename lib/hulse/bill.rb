module Hulse
  class Bill
    extend Memoist

    attr_reader :url, :number, :title, :sponsor_url, :sponsor_bioguide, :sponsor_party, :sponsor_state, :introduced_date, :bill_type, :committees,
    :latest_action_text, :latest_action_date, :status, :actions_url, :chamber, :amendments, :cosponsors, :total_cosponsors, :bipartisan_cosponsors,
    :republican_cospsonsors, :democratic_cosponsors, :independent_cosponsors, :versions, :committee_actions_url, :versions_url, :cosponsors_url,
    :subjects, :subjects_url, :policy_area

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
      b = self.new(result)
      b.subjects
      return b
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
        committees: cmtes, latest_action_text: latest_action, latest_action_date: latest_action_date, status: status_tracker,
        amendments: nil, cosponsors: nil, related_bills: nil}
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
      begin
        Date.strptime(table.css('tr').first.children[3].children.last.text.strip.split[1].split(')').first, '%m/%d/%Y')
      rescue
        puts table.css('tr').first.children[3].children.last.text.strip
      end
    end

    def self.get_sponsor(table)
      url = table.css('tr').first.children[3].children.first['href']
      bioguide_id = table.css('tr').first.children[3].children.first['href'].split('/').last
      [url, bioguide_id]
    end

    def self.get_latest_action(table)
      return [nil, nil] if table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text == 'Action data to be retrieved.'
      text = table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split("(").first.strip
      date = Date.strptime(table.css('tr').detect{|row| row.children[1].text == 'Latest Action:'}.children[3].children.first.text.split.first, '%m/%d/%Y')
      [text, date]
    end

    def self.get_status_tracker(table)
      tr = table.css('tr').detect{|row| row.children[1].text == 'Tracker:'}
      tr.children[3].children.first.text.gsub('This bill has the status','').strip if tr
    end

    def self.get_party_and_state(html)
      html.text.scan(/\[(.*)\]/).first.first.split('-').first(2)
    end

    def self.bills_updated_since(date=Date.today)


    end

    def self.scrape_congress(congress)
      results = []
      html = fetch(congress)
      total_bills = html.css('strong').first.next.text.strip.split('of ').last.gsub(',','').to_i
      pages = (total_bills.to_f/250.0).round
      results << scrape_page(html)
      (2..pages).each do |page|
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
      status_tracker = begin html.css('p.hide_fromsighted').children.first.text.gsub('This bill has the status','').strip rescue nil end
      party, state = get_party_and_state(table.css('tr').first.children[3].children.first)
      sponsor_url, sponsor_bioguide = get_sponsor(table)
      introduced_date = get_introduced_date(table)
      latest_action_text, latest_action_date = get_latest_action(table)
      create_from_result({url: url, number: bill_number, title: title, sponsor_url: sponsor_url, sponsor_bioguide: sponsor_bioguide,
      sponsor_party: party, sponsor_state: state.gsub(']',''), introduced_date: introduced_date, bill_type: Hulse::Utils.bill_type(bill_number)['title'],
      committees: cmtes, latest_action_text: latest_action, latest_action_date: latest_action_date, status: status_tracker, subjects: nil,
      amendments: nil, cosponsors: nil, related_bills: nil})
    end

    def self.most_viewed
      most_viewed = []
      url = "https://www.congress.gov/resources/display/content/Most-Viewed+Bills"
      doc = HTTParty.get(url)
      html = Nokogiri::HTML(doc.parsed_response)
      current_week_date = Date.parse(html.css('h2').text)
      current_week = html.css("table").first.css('tr')
      current_week.each do |row|
        rank = row.css('td').first.text.scan(/\d+/).first.to_i
        bill, congress = row.css('td')[1].text.split
        congress = congress.scan(/\d+/).first.to_i
        title = row.css('td')[2].text.strip
        most_viewed << [ current_week_date, rank, bill, congress, title]
      end
      most_viewed
    end

    def chamber
      number.chars.first == 'H' ? 'House' : 'Senate'
    end

    def actions_url
      url + '/all-actions'
    end

    def actions
      get_actions
    end

    def get_actions
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
      get_related_bills
    end

    def get_related_bills
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
      get_amendments
    end

    def get_amendments
      Amendment.scrape_amendments(amendments_url)
    end

    def cosponsors_url
      url + '/cosponsors'
    end

    def cosponsors
      get_cosponsors
    end

    def get_cosponsors
      cosponsors = []
      doc = HTTParty.get(cosponsors_url)
      html = Nokogiri::HTML(doc.parsed_response)
      table = html.css("table.item_table")
      return [] if table.css('tr')[1..-1].nil?
      table.css('tr')[1..-1].each do |row|
        next if row.css('td').first.children[1].nil?
        original = row.css('td').first.children[1].text.chars.last == '*' ? true : false
        party, state = Bill.get_party_and_state(row.css('td').first.children[1])
        cosponsors << {cosponsor_name: row.css('td').first.children[1].text, date: Date.strptime(row.css('td')[1].text, "%m/%d/%Y"),
          cosponsor_bioguide: row.css('td').first.children[1]['href'].split('/').last, cosponsor_url: row.css('td').first.children[1]['href'],
          cosponsor_party: party, cosponsor_state: state, original: original}
      end
      cosponsors
    end

    def total_cosponsors
      cosponsors.size
    end

    def bipartisan_cosponsors?
      cosponsors.map{|s| s[:cosponsor_party]}.uniq == sponsor_party ? false : true
    end

    def republican_cospsonsors
      cosponsors.map{|s| s[:cosponsor_party] == 'R'}
    end

    def democratic_cosponsors
      cosponsors.map{|s| s[:cosponsor_party] == 'D'}
    end

    def independent_cosponsors
      cosponsors.map{|s| s[:cosponsor_party] == 'I'}
    end

    def versions_url
      url + '/text'
    end

    def versions
      get_versions
    end

    def get_versions
      versions = []
      doc = HTTParty.get(versions_url)
      html = Nokogiri::HTML(doc.parsed_response)
      number = html.css("label.tntFormLabel").text.strip.scan(/\d+/).first.to_i
      html.css("select").last.children.select{|c| !c['value'].nil?}.each do |version|
        versions << {url: versions_url+"/#{version['value']}", version: version.text.strip, stage: version['value'].upcase}
      end
      versions
    end

    def committee_actions_url
      url + '/committees'
    end

    def committee_actions
      get_committee_actions
    end

    def get_committee_actions
      committee_actions = []
      doc = HTTParty.get(committee_actions_url)
      html = Nokogiri::HTML(doc.parsed_response)
      table = html.css('table.table_committee')
      return [] if table.css('tr')[1..-1].nil?
      most_recent_value = nil
      committee_names = table.css('tr')[2..-1].map{|row| row.css('th').first.text unless row.css('th').empty?}.map{ |entry| most_recent_value = (entry || most_recent_value) }
      table.css('tr')[2..-1].each_with_index do |row, i|
        next if row.text.strip == ''
        committee = committee_names[i]
        td = row.children[1].text.strip == '' ? -2 : 0
        if row.children[6+td].children.text == ''
          report_url = nil
          report_title = nil
        else
          report_url = "https://www.congress.gov"+row.children[6+td].children.first['href']
          report_title = row.children[6+td].children.text
        end
        committee_actions << {committee: committee, date: Date.strptime(row.children[2+td].text, "%m/%d/%Y"), action: row.children[4+td].text,
          report_url: report_url, report_title: report_title}
      end
      committee_actions
    end

    def subjects_url
      url + '/subjects'
    end

    def subjects
      get_subjects
    end

    def policy_area
      @policy_area
    end

    def get_subjects
      subjects = []
      doc = HTTParty.get(subjects_url)
      html = Nokogiri::HTML(doc.parsed_response)
      if html.css('ul.plain li').first
        instance_variable_set("@policy_area", html.css('ul.plain li').first.text)
        html.css('ul.plain li')[1..-1].map{|r| r.text.strip}
      end
    end

    memoize :cosponsors, :actions, :amendments, :related_bills, :versions, :committee_actions, :subjects, :policy_area
  end
end
