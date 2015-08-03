module Hulse
  class Record

    attr_reader :date, :section, :topics, :html

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def to_s
      section
    end

    def self.base_url(date=nil)
      if date
        year, month, day = date.year, date.month, date.day
      else
        date = Date.today-1
        year, month, day = date.year, date.month, date.day
      end
      "https://www.congress.gov/congressional-record/#{year}/#{month}/#{day}/"
    end

    def self.daily_digest(date=nil)
      doc = HTTParty.get(base_url(date)+'daily-digest')
      html = Nokogiri::HTML(doc.parsed_response)
      (html/:pre).text
    end

    def self.senate(date=nil)
      doc = HTTParty.get(base_url(date)+'senate-section')
      create_from_html(Nokogiri::HTML(doc.parsed_response), date, 'senate')
    end

    def self.house(date=nil)
      doc = HTTParty.get(base_url(date)+'house-section')
      create_from_html(Nokogiri::HTML(doc.parsed_response), date, 'house')
    end

    def self.extension_of_remarks(date=nil)
      doc = HTTParty.get(base_url(date)+'extensions-of-remarks-section')
      create_from_html(Nokogiri::HTML(doc.parsed_response), date, 'extension')
    end

    def self.create_from_html(html, date, section)
      section_topics = topics(html)
      self.new(date: date,
        section: section,
        topics: section_topics,
        html: html
      )
    end

    def self.topics(html)
      (html/:td).map{|d| d.children[1]}.compact.map{|l| {url: l['href'], title: l.text.strip}}
    end

    def has_senate_explanations?
      topics.select{|l| l[:title].include?("VOTE EXPLANATION")}.empty? ? false : true
    end

    def senate_explanations
      topics.select{|l| l[:title].include?("VOTE EXPLANATION")}
    end

    def has_personal_explanations?
      topics.select{|l| l[:title].include?("PERSONAL EXPLANATION")}.empty? ? false : true
    end

    def personal_explanations
      topics.select{|l| l[:title].include?("PERSONAL EXPLANATION")}
    end

    def has_committee_elections?
      topics.select{|l| l[:title].include?("COMMITTEE ELECTION")}.empty? ? false : true
    end

    def committee_elections
      topics.select{|l| l[:title].include?("COMMITTEE ELECTION")}
    end

    def has_committee_resignations?
      topics.select{|l| l[:title].include?("COMMITTEE RESIGNATION")}.empty? ? false : true
    end

    def chairman_designations
      topics.select{|l| l[:title].include?("DESIGNATING THE CHAIRMAN")}
    end

    def ranking_designations
      topics.select{|l| l[:title].include?("DESIGNATING THE RANKING")}
    end

    def leaves_of_absence
      topics.select{|l| l[:title].include?("LEAVE OF ABSENCE")}
    end

    def committee_leaves_of_absence
      topics.select{|l| l[:title].include?("COMMITTEE LEAVE OF ABSENCE")}
    end
  end
end
