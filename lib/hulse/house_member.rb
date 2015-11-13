module Hulse
  class HouseMember

    attr_reader :bioguide_id, :sort_name, :last_name, :first_name, :middle_name, :suffix, :courtesy, :official_name,
    :formal_name, :party, :caucus_party, :state_postal, :state_name, :district_code, :hometown, :office_building,
    :office_room, :office_zip, :phone, :last_elected_date, :sworn_date, :committees, :subcommittees, :is_vacant,
    :footnote, :predecessor, :vacancy_date, :sponsored_bills, :cosponsored_bills, :congressdotgov_url

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.current
      url = "http://clerk.house.gov/xml/lists/MemberData.xml"
      response = HTTParty.get(url)
      congressdotgov_results = congressdotgov(Hulse::Utils.current_congress)
      self.create_from_xml(response, congressdotgov_results)
    end

    def self.congressdotgov(congress)
      results = []
      url = "https://www.congress.gov/sponsors-cosponsors/#{congress.to_i.ordinalize.to_s}-congress/representatives/all"
      response = HTTParty.get(url)
      html = Nokogiri::HTML(response.parsed_response)
      table = (html/:table).first
      (table/:tr)[1..-1].each do |row|
        results << { bioguide_id: (row/:td).first.children.first['href'].split('/').last, member_url: (row/:td).first.children.first['href'], sponsored_bills: (row/:td)[1].text.gsub(' Sponsored','').to_i, cosponsored_bills: (row/:td)[2].text.gsub(' Cosponsored','').to_i}
      end
      results
    end

    def self.create_from_xml(response, congressdotgov_results)
      members = []
      response['MemberData']['members']['member'].each do |member|
        if member['member_info']['elected_date']['date'] == ''
          footnote = member['member_info']['footnote']
          predecessor = member['predecessor_info']
          vacancy_date = Date.parse(member['predecessor_info']['pred_vacate_date']['date'])
          vacant = true
          dotgov = {bioguide_id: nil, member_url: nil, sponsored_bills: nil, cosponsored_bills: nil}
        else
          footnote, predecessor, vacancy_date = nil
          vacant = false
          dotgov = congressdotgov_results.detect{|c| c[:bioguide_id] == member['member_info']['bioguideID']}
        end

        members << self.new(bioguide_id: member['member_info']['bioguideID'],
          sort_name: member['member_info']['sort_name'],
          last_name: member['member_info']['lastname'],
          first_name: member['member_info']['firstname'],
          middle_name: member['member_info']['middlename'],
          suffix: member['member_info']['suffix'],
          courtesy: member['member_info']['courtesy'],
          official_name: member['member_info']['official_name'],
          formal_name: member['member_info']['formal_name'],
          party: member['member_info']['party'],
          caucus_party: member['member_info']['caucus'],
          state_postal: member['member_info']['state']['postal_code'],
          state_name: member['member_info']['state']['state_fullname'],
          district: member['member_info']['district'],
          district_code: member['statedistrict'],
          hometown: member['member_info']['townname'],
          office_building: member['member_info']['office_building'],
          office_room: member['member_info']['office_room'],
          office_zip: member['member_info']['office_zip']+'-'+member['member_info']['office_zip_suffix'],
          phone: member['member_info']['phone'],
          last_elected_date: begin Date.parse(member['member_info']['elected_date']['date']) rescue nil end,
          sworn_date: begin Date.parse(member['member_info']['sworn_date']['date']) rescue nil end,
          committees: member['committee_assignments']['committee'],
          subcommittees: member['committee_assignments']['subcommittee'],
          is_vacant: vacant,
          footnote: footnote,
          predecessor: predecessor,
          vacancy_date: vacancy_date,
          sponsored_bills: dotgov[:sponsored_bills],
          cosponsored_bills: dotgov[:cosponsored_bills],
          congressdotgov_url: dotgov[:member_url]
        )
      end
      members
    end
  end
end
