module Hulse
  class HouseFloor

    attr_reader :legislative_day, :finished, :actions, :congress, :session, :url, :next_session

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.latest_dates
      url = "http://clerk.house.gov/floorsummary/floor-rss.ashx"
      response = HTTParty.get(url)
      xml = response.parsed_response
      xml['rss']['channel']['item'].map{|i| Date.parse(i['pubDate']).to_s}.uniq
    end

    def self.date(date)
      url = "http://clerk.house.gov/floorsummary/Download.aspx?file=#{date.to_s.gsub('-','')}.xml"
      response = HTTParty.get(url)
      xml = HTTParty::Parser.call(response.parsed_response, :xml)
      self.create_from_xml(xml)
    end

    def self.create_from_xml(xml)
      actions = []
      xml['legislative_activity']['floor_actions']['floor_action'].each do |action|
        actions << action.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end
      results = self.new(congress: xml['legislative_activity']['legislative_congress']['congress'].to_i,
      session: xml['legislative_activity']['legislative_congress']['session'].to_i,
      legislative_day: xml['legislative_activity']['legislative_day']['__content__'].strip,
      finished: xml['legislative_activity']['floor_actions']['legislative_day_finished']['__content__'],
      url: "http://clerk.house.gov/floorsummary/floor.aspx?day=#{xml['legislative_activity']['legislative_day']['date']}",
      next_session: DateTime.parse(xml['legislative_activity']['floor_actions']['legislative_day_finished']['next_legislative_day_convenes']),
      actions: actions)
    end
  end
end
