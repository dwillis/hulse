module Hulse
  class HouseFloor

    attr_reader :legislative_day, :finished, :actions


    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.date(date)
      url = "http://clerk.house.gov/floorsummary/Download.aspx?file=#{date.to_s.gsub('-','')}.xml"
      response = HTTParty.get(url)
      xml = HTTParty::Parser.call(response.parsed_response, :xml)
      self.create_from_xml(xml)
    end

    def self.create_from_xml(xml)
      results = {}
      actions = []
      results['congress'] = xml['legislative_activity']['legislative_congress']['congress'].to_i
      results['session'] = xml['legislative_activity']['legislative_congress']['session'].to_i
      results['legislative_day'] = xml['legislative_activity']['legislative_day']['__content__'].strip
      results['finished'] = xml['legislative_activity']['floor_actions']['legislative_day_finished']['__content__']
      xml['legislative_activity']['floor_actions']['floor_action'].each do |action|
        actions << action.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end
      results['actions'] = actions
      results
    end
  end
end
