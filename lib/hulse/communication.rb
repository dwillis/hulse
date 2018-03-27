module Hulse
  class Communication

    attr_reader :id, :date, :committee, :url, :text, :requirement, :requirement_url

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def to_s
      id
    end

    def self.presidential(page=1)
      comms = []
      doc = RestClient.get("https://www.congress.gov/communications?q=%7B%22communication-code%22%3A%22PM%22%7D&pageSize=250&page=#{page}")
      html = Nokogiri::HTML(doc.body)
      html.css('ol li[@class="expanded"]').each do |row|
        comms << create(row)
      end
      comms
    end

    def self.executive(page=1)
      comms = []
      doc = RestClient.get("https://www.congress.gov/communications?q=%7B%22communication-code%22%3A%22EC%22%7D&pageSize=250&page=#{page}")
      html = Nokogiri::HTML(doc.body)
      html.css('ol li[@class="expanded"]').each do |row|
        comms << create(row)
      end
      comms
    end

    def self.house(page=1)
      comms = []
      doc = RestClient.get("https://www.congress.gov/search?q={%22source%22:%22house-communications%22}&pageSize=250&page=#{page}&pageSort=crDateDesc")
      html = Nokogiri::HTML(doc.body)
      html.css('ol li[@class="expanded"]').each do |row|
        puts row.children[3].children[0].text
        comms << Hulse::Communication.create_house(row)
      end
      comms
    end

    def self.senate(page=1)
      comms = []
      doc = RestClient.get("https://www.congress.gov/search?pageSize=250&q=%7B%22source%22%3A%22senate-communications%22%7D&page=#{page}&pageSort=crDateDesc")
      html = Nokogiri::HTML(doc.body)
      html.css('ol li[@class="expanded"]').each do |row|
        comms << create_senate(row)
      end
      comms
    end

    def self.create(row)
      self.new(id: row.children[3].children[0].text,
        date: Date.strptime(row.children[3].children[1].text.split[1], "%m/%d/%Y"),
        committee: row.children[3].children[2].text,
        url: row.children[3].children[0]['href'],
        text: row.children[5].text
      )
    end

    def self.create_house(row)
      self.new(id: row.children[3].children[0].text,
        date: Date.strptime(row.children[3].children[1].text.split[1], "%m/%d/%Y"),
        committee: row.children[3].children[2].text,
        text: row.children[5].text,
        url: row.children[3].children[0]['href'],
        requirement: row.children[7].text.split(': ').last,
        requirement_url: row.children[7].text.split(': ').last.nil? ? nil : "https://www.congress.gov/house-communication-requirement/#{row.children[7].text.split(': ').last.gsub('R','')}"
      )
    end

    def self.create_senate(row)
      self.new(id: row.children[3].children[0].text,
        date: Date.strptime(row.children[3].children[1].text.split[1], "%m/%d/%Y"),
        committee: row.children[3].children[2].text,
        text: row.children[5].text,
        url: row.children[3].children[0]['href']
      )
    end

  end
end
