module Hulse
  class SenateMember

    attr_reader :bioguide_id, :last_name, :first_name, :title, :senate_class, :address, :email, :website,
    :party, :state_postal

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.current
      url = "http://www.senate.gov/general/contact_information/senators_cfm.xml"
      response = HTTParty.get(url)
      self.create_from_xml(response)
    end

    def self.congressdotgov(congress)
      results = []
      url = "https://www.congress.gov/sponsors-cosponsors/#{congress.to_i.ordinalize.to_s}-congress/senators/all"
      response = HTTParty.get(url)
      html = Nokogiri::HTML(response.parsed_response)
      table = (html/:table).first
      (table/:tr)[1..-1].each do |row|
        results << { bioguide_id: (row/:td).first.children.first['href'].split('/').last, member_url: (row/:td).first.children.first['href'], sponsored_bills: (row/:td)[1].text.gsub(' Sponsored','').to_i, cosponsored_bills: (row/:td)[2].text.gsub(' Cosponsored','').to_i}
      end
      results
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
          senate_class: member['class'],
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
