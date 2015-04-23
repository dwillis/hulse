module Hulse
  class SenateMember

    attr_reader :bioguide_id, :sort_name, :last_name, :first_name, :middle_name, :suffix, :courtesy, :official_name,
    :formal_name, :party, :caucus_party, :state_postal, :state_name, :district_code, :hometown, :office_building,
    :office_room, :office_zip, :phone, :last_elected_date, :sworn_date, :committees, :subcommittees, :is_vacant,
    :footnote, :predecessor, :vacancy_date

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.list
      url = "http://www.senate.gov/general/contact_information/senators_cfm.xml"
      response = HTTParty.get(url)
      self.create_from_xml(response)
    end


    def self.create_from_xml(response)
      members = []
      response['contact_information']['member'].each do |member|
        members << self.new(bioguide_id: member['bioguide_id'],
          title: member['member_full'],
          last_name: member['last_name'],
          first_name: member['first_name'],
          party: member['party'],
          state_postal: member['state'],
          class: member['class'],
          address: member['address'],
          phone: member['phone'],
          email: member['email'],
          website: member['website']
        )
      end
      members
    end
  end
end
