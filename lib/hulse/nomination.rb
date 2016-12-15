# encoding: utf-8
module Hulse
  class Nomination

    attr_reader :id, :name, :date, :committee, :committee_code, :url, :text, :actions, :agency, :description, :date_received, :latest_action_text, :latest_action_date, :status, :privileged, :civilian

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.civilian_types
      ['NomPrivileged.xml', 'NomCivilianPendingCommittee.xml', 'NomCivilianConfirmed.xml', 'NomCivilianPendingCalendar.xml', 'NomWithdrawn.xml', 'NomFailedOrReturned.xml']
    end

    def self.noncivilian_types
      ['NomNonCivilianPendingCommittee', 'NomNonCivilianConfirmed.xml', 'NomNonCivilianPendingCalendar.xml']
    end

    def self.fetch_and_parse_civilians
      results = []
      base_url = "http://www.senate.gov/legislative/LIS/nominations/"
      civilian_types.each do |nom_type|
        civilian = true
        status, privileged = check_type_for_status(nom_type)
        response = HTTParty.get(base_url+nom_type)
        results << parse_xml(response.parsed_response)
      end
      results
    end

    def self.fetch_and_parse_noncivilian
      results = []
      base_url = "http://www.senate.gov/legislative/LIS/nominations/"
      noncivilian_types.each do |nom_type|
        civilian = false
        status, privileged = check_type_for_status(nom_type)
        response = HTTParty.get(base_url+nom_type)
        results << parse_xml(response.parsed_response)
      end
      results
    end

    def self.check_type_for_status(nom_type)
      privileged = false
      if nom_type.include?('Confirmed')
        status = 'confirmed'
      elsif nom_type.include?('Privileged')
        privileged = true
        status = 'Pending Floor Vote'
      elsif nom_type.include?('PendingCommittee')
        status = 'Pending Committee'
      elsif nom_type.include?('PendingCalendar')
        status = 'Pending Floor Vote'
      end
      [status, privileged]
    end

    def self.parse_xml(parsed_response)
      results = []
      parsed_response['Nominations']['Nomination'].each do |nom|
        results << {
          url: nil,
          id: nom['NominationDisplayNumber']['__content__'],
          civilian: nom['Civilian'],
          privileged: nom['Privileged'],
          name: nil,
          agency: nom['Organization'],
          description: nom['ReportingDescription'],
          date_received: nom['ReceivedDate'],
          committee: nom['Committees']['CommitteeReferrals']['Committee']['CommitteeFullName'],
          committee_code: nom['Committees']['CommitteeReferrals']['Committee']['SenateCommitteeCode'],
          latest_action_text: nil,
          latest_action_date: nil,
          status: nil
        }
      end
      results
    end

    def self.fetch(congress, page=1)
      doc = HTTParty.get("https://www.congress.gov/search?q={%22source%22:%22nominations%22,%22congress%22:%22#{congress}%22}&pageSize=250&page=#{page}")
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
      html.css('ol.basic-search-results-lists li.expanded').each do |nom|
        puts nom.css('span.result-heading').first.children[1].text
        raw_title = nom.css('span.result-heading').first.children[3].text.encode(Encoding.find('ASCII'), :invalid => :replace, :undef => :replace, :replace => '').strip.split('  ')
        if raw_title.size > 1
          name = raw_title.first
          agency = raw_title.last
        else
          name = nil
          agency = raw_title.first
        end
        latest_action_text = nom.css('span.result-item').detect{|row| row.text.strip.include?('Latest Action:')}.children[2].text.strip.split(' (').first
        if latest_action_text.include?("Confirmed")
          status = 'Confirmed'
        elsif latest_action_text.include?("withdrawal of nomination")
          status = "Withdrawn"
        else
          status = 'Pending'
        end
        results << {
          url: nom.css('span.result-heading').first.children[1]['href'],
          id: nom.css('span.result-heading').first.children[1].text,
          name: name,
          agency: agency,
          description: nom.css('span.result-item').first.text.strip,
          date_received: Date.strptime(nom.css('span.result-item').detect{|row| row.text.strip.include?('Date Received from President:')}.children[2].text.strip, '%m/%d/%Y'),
          committee: nom.css('span.result-item').detect{|row| row.text.strip.include?('Committee:')}.children[2].text.strip,
          latest_action_text: latest_action_text,
          latest_action_date: Date.strptime(nom.css('span.result-item').detect{|row| row.text.strip.include?('Latest Action:')}.children[2].text.strip.split(' (').first, '%m/%d/%Y'),
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
      name = name.strip if name
      if agency
        agency = agency.strip
      else
        agency = name.strip
        name = nil
      end
      c = html.css('h2').detect{|h| h.text == 'Committee'}
      committee = c.next.next.text.strip if c
      if html.css('h2').detect{|h| h.text == 'Description'}
        d = html.css('h2').detect{|h| h.text == 'Description'}
        description = d.next.next.text.strip if d
      elsif html.css('h2').detect{|h| h.text == 'Nominees'}
        description = html.css('h2').detect{|h| h.text == 'Nominees'}.next.next.text.strip
      end
      dr = html.css('h2').detect{|h| h.text == 'Date Received from President'}
      date_received = Date.strptime(dr.next.next.text.strip, '%m/%d/%Y') if dr
      la = html.css('h2').detect{|h| h.text == 'Latest Action'}
      latest_action_text = la.next.next.text.strip if la
      if latest_action_text and latest_action_text.include?("Confirmed")
        status = 'Confirmed'
      elsif latest_action_text and latest_action_text.include?("withdrawal of nomination")
        status = "Withdrawn"
      else
        status = 'Pending'
      end

      table = html.css('table.item_table')
      table.css('tr')[1..-1].each do |row|
        actions << {date: Date.strptime(row.css('td').first.text, "%m/%d/%Y"), action: row.css('td').last.children.first.text.strip}
      end
      result = {id: nom_number.strip, name: name, agency: agency, description: description, committee: committee, date_received: date_received, latest_action_text: latest_action_text, status: status, actions: actions}
      create_from_result(result)
    end
  end
end
