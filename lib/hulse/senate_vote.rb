module Hulse
  class SenateVote

    attr_reader :congress, :session, :year, :vote_number, :vote_timestamp, :updated_at, :vote_question_text, :vote_document_text,
    :vote_result_text, :question, :vote_title, :majority_requirement, :vote_result, :document, :amendment, :vote_count, :tie_breaker, :members, 
    :vote_date, :issue

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end
    
    def self.find(year, vote)
      congress, session = Hulse::Utils.convert_year_to_congress_and_session(year)
      url = "http://www.senate.gov/legislative/LIS/roll_call_votes/vote#{congress}#{session}/vote_#{congress}_#{session}_#{vote.to_s.rjust(5,"0")}.xml"
      response = HTTParty.get(url)
      self.create_from_vote(response.parsed_response['roll_call_vote'])
    end

    def self.create_from_vote(response)
      members = []
      response['members']['member'].each do |m|
        members << m.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end
      self.new(congress: response['congress'].to_i,
        session: response['session'].to_i,
        year: response['congress_year'].to_i,
        vote_number: response['vote_number'].to_i,
        vote_timestamp: DateTime.parse(response['vote_date']),
        updated_at: DateTime.parse(response['modify_date']),
        vote_question_text: response['vote_question_text'],
        vote_document_text: response['vote_document_text'],
        vote_result_text: response['vote_result_text'],
        question: response['question'],
        vote_title: response['vote_title'],
        majority_requirement: response['majority_requirement'],
        vote_result: response['vote_result'],
        document: response['document'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo},
        amendment: response['amendment'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo},
        vote_count: response['count'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo},
        tie_breaker: response['tie_breaker'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo},
        members: members
      )
    end
    
    def self.summary(year)
      congress, session = Hulse::Utils.convert_year_to_congress_and_session(year)
      url = "http://www.senate.gov/legislative/LIS/roll_call_lists/vote_menu_#{congress}_#{session}.xml"
      response = HTTParty.get(url)
      votes = response.parsed_response['vote_summary']['votes']['vote']
      votes.map{|v| self.new(congress: congress, session: session, year: year, vote_number: v['vote_number'], vote_date: Date.strptime(v['vote_date']+"-#{year}", "%d-%b-%Y"), issue: v['issue'], 
        question: v['question'], vote_result: v['result'], vote_count: v['vote_tally'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}, vote_title: v['title'])}
    end
  end
end
