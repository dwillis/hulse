module Hulse
  class HouseCommittee

    attr_reader :url, :name, :code, :members, :republicans, :democrats, :subcommittees

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.fetch(url)
      doc = HTTParty.get(url)
      Nokogiri::HTML(doc.parsed_response)
    end

    def self.create_from_results(results)
      results.map{|r| self.new(r)}
    end

    def self.find_cmte_members(members, cmte_code)
      results = []
      members.each do |m|
        results << m unless m.committees.select{|c| c['comcode'] == cmte_code }.empty?
      end
      results
    end

    def self.find_subcmte_members(cmte_members, subcmte_code)
      results = []
      cmte_members.each do |cm|
        results << cm unless cm.subcommittees.select{|sc| sc["subcomcode"] == subcmte_code}.empty?
      end
      results
    end

    def self.current
      members = HouseMember.current
      results = []
      html = fetch("http://clerk.house.gov/committee_info/index.aspx")
      html.css('#com_directory ul li').each do |cmte|
        subcmtes = []
        cmte_url = "http://clerk.house.gov"+cmte.children[1]['href']
        cmte_code = cmte.children[1]['href'].split('=').last
        cmte_html = fetch(cmte_url)
        cmte_members = find_cmte_members(members, cmte_code)
        cmte_html.css('#subcom_list ul li').each do |subcmte|
          subcmte_code = subcmte.children[1]['href'].split('=').last
          subcmte_members = find_subcmte_members(cmte_members, subcmte_code)
          subcmtes << { url: "http://clerk.house.gov"+subcmte.children[1]['href'], name: subcmte.children[1].text.strip, code: subcmte_code, members: subcmte_members, republicans: subcmte_members.select{|cm| cm.party == 'R'}.size, democrats: subcmte_members.select{|cm| cm.party == 'D'}.size }
        end
        results << { url: cmte_url, name: cmte.children[1].text.strip, code: cmte_code, subcommittees: subcmtes, members: members, republicans: cmte_members.select{|cm| cm.party == 'R'}.size, democrats: cmte_members.select{|cm| cm.party == 'D'}.size}
      end
      create_from_results(results)
    end
  end
end
