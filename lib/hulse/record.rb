module Hulse
  class Record

    def self.base_url(date=nil)
      if date
        year, month, day = date.year, date.month, date.day
      else
        date = Date.today-1
        year, month, day = date.year, date.month, date.day
      end
      "http://beta.congress.gov/congressional-record/#{year}/#{month}/#{day}/"
    end

    def self.senate(date=nil)
      begin
        doc = Nokogiri::HTML(open(base_url(date)+'senate-section'))
      rescue
        return nil
      end
    end


    def self.senate_topics(html)
      links = (html/:td).map{|d| d.children[1]}.compact
    end

    def self.senate_explanations(html)
      links = (html/:td).map{|d| d.children[1]}.compact
      vote_explanations = links.select{|l| l.text.include?("VOTE EXPLANATION")}
      VoteExplanation.create(vote_explanations)
    end

    def self.house(base_url)
      ['house-section', 'extensions-of-remarks-section'].each do |section|
        begin
          doc = Nokogiri::HTML(open(base_url+section))
        rescue
          next
        end
        links = (doc/:td).map{|d| d.children[1]}.compact
        personal_explanations = links.select{|l| l.text.include?("PERSONAL EXPLANATION")}
        links.select{|l| l.text.include?("COMMITTEE ELECTION")}.map{|l| Audit.create(:datatype_id => Datatype::DAILY_DIGEST_PARSER, :success => true, :description => "Found committee elections on #{date.to_s}", :url => l['href'])} unless links.select{|l| l.text.include?("COMMITTEE ELECTION")}.empty?
        links.select{|l| l.text.include?("DESIGNATING THE CHAIRMAN")}.map{|l| Audit.create(:datatype_id => Datatype::DAILY_DIGEST_PARSER, :success => true, :description => "Found committee chairman designations on #{date.to_s}", :url => l['href'])} unless links.select{|l| l.text.include?("DESIGNATING THE CHAIRMAN")}.empty?
        links.select{|l| l.text.include?("DESIGNATING THE RANKING")}.map{|l| Audit.create(:datatype_id => Datatype::DAILY_DIGEST_PARSER, :success => true, :description => "Found committee ranking member designations on #{date.to_s}", :url => l['href'])} unless links.select{|l| l.text.include?("DESIGNATING THE RANKING")}.empty?
        links.select{|l| l.text == "LEAVE OF ABSENCE"}.map{|l| Audit.create(:datatype_id => Datatype::DAILY_DIGEST_PARSER, :success => true, :description => "Found leave of absence on #{date.to_s}", :url => l['href'])} unless links.select{|l| l.text == "LEAVE OF ABSENCE"}.empty?
        links.select{|l| l.text.include?("COMMITTEE LEAVE OF ABSENCE")}.map{|l| Audit.create(:datatype_id => Datatype::DAILY_DIGEST_PARSER, :success => true, :description => "Found committee leave of absence on #{date.to_s}", :url => l['href'])} unless links.select{|l| l.text.include?("COMMITTEE LEAVE OF ABSENCE")}.empty?
        links.select{|l| l.text.include?("COMMITTEE RESIGNATION")}.map{|l| Audit.create(:datatype_id => Datatype::DAILY_DIGEST_PARSER, :success => true, :description => "Found committee resignation on #{date.to_s}", :url => l['href'])} unless links.select{|l| l.text.include?("COMMITTEE RESIGNATION")}.empty?
        unless personal_explanations.empty?
          personal_explanations.map{|p| PersonalExplanation.find_or_create_by_date_and_url(:date => date, :url => p['href'], :congress_id => congress)}
          Audit.create(:datatype_id => Datatype::PERSONAL_EXPLANATIONS, :success => true, :description => "Found House personal explanations made on #{date.to_s}")
        end
      end
    end


  end
end