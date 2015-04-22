module Hulse
  class HouseMember

    attr_reader


    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.clerk_list
      url = "http://clerk.house.gov/xml/lists/MemberData.xml"
      response = HTTParty.get(url)
      self.create_from_xml(response)
    end


    def self.create_from_xml(response)
      members = []
      response['MemberData']['members']['member'].each do |member|
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
          caucus: member['member_info']['caucus'],
          state_postal: member['member_info']['state']['postal_code'],
          state_name: member['member_info']['state']['state_fullname'],
          district: member['member_info']['district'],
          districtcode: member['statedistrict'],
          hometown: member['member_info']['townname'],
          office_building: member['member_info']['office_building'],
          office_room: member['member_info']['office_room'],
          office_zip: member['member_info']['office_zip']+'-'+member['member_info']['office_zip_suffix'],
          phone: member['member_info']['phone'],
          last_elected_date: Date.parse(member['member_info']['elected_date']['date']),
          sworn_date: Date.parse(member['member_info']['sworn_date']['date']),
          committees: member['committee_assignments']['committee'],
          subcommittees: member['committee_assignments']['subcommittee']
        )
      end
    end
    members
  end
end
