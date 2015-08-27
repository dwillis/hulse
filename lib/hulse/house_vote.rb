module Hulse
  class HouseVote

    attr_reader :majority, :congress, :session, :chamber, :vote_number, :bill_number, :question, :vote_type, :vote_result, :vote_timestamp, :description,
    :party_summary, :vote_count, :members, :amendment_number, :amendment_author

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.latest_vote(year)
      url = "http://clerk.house.gov/evs/#{year}/index.asp"
      response = HTTParty.get(url)
      doc = Nokogiri::HTML(response.parsed_response)
      (doc/:a).first.text.to_i
    end

    def self.find(year, vote)
      url = "http://clerk.house.gov/evs/#{year.to_s}/roll#{vote.to_s.rjust(3,"0")}.xml"
      response = HTTParty.get(url)
      self.create_from_vote(response.parsed_response['rollcall_vote'])
    end

    def self.create_from_vote(response)
      party_totals = []
      if response['vote_metadata']['vote_totals']['totals_by_party']
        response['vote_metadata']['vote_totals']['totals_by_party'].each do |p|
          party_totals << p.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        end
      end
      members = []
      mappings = {"__content__" => "name"}
      if response['vote_data']
        response['vote_data']['recorded_vote'].each do |m|
          m['legislator']['name'] = m['legislator'].delete('__content__')
          m['legislator']['bioguide_id'] = m['legislator'].delete('name_id') # prior to 2003, bioguide IDs were not used in the XML
          m['legislator']['vote'] = m['vote']
          members << m['legislator'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        end
      end
      if response['vote_metadata']['vote_question'] == 'Election of the Speaker'
        vote_counts = response['vote_metadata']['vote_totals']['totals_by_candidate'].reject{|k,v| k == 'total_stub'}.inject({}){|memo,(k,v)| memo[k['candidate'].to_sym] = k['candidate_total'].to_i; memo}
      else
        vote_counts = response['vote_metadata']['vote_totals']['totals_by_vote'].reject{|k,v| k == 'total_stub'}.inject({}){|memo,(k,v)| memo[k.to_sym] = v.to_i; memo}
      end
      self.new(majority: response['vote_metadata']['majority'],
        congress: response['vote_metadata']['congress'].to_i,
        session: response['vote_metadata']['session'],
        chamber: response['vote_metadata']['chamber'],
        vote_number: response['vote_metadata']['rollcall_num'].to_i,
        bill_number: response['vote_metadata']['legis_num'],
        question: response['vote_metadata']['vote_question'],
        amendment_number: response['vote_metadata']['amendment_num'],
        amendment_author: response['vote_metadata']['amendment_author'],
        vote_type: response['vote_metadata']['vote_type'],
        vote_result: response['vote_metadata']['vote_result'],
        vote_timestamp: begin DateTime.parse(response['vote_metadata']['action_date'] + ' ' + response['vote_metadata']['action_time']['time_etz']) rescue nil end,
        description: response['vote_metadata']['vote_desc'],
        party_summary: party_totals,
        vote_count: vote_counts,
        members: members)
      end
  end
end
