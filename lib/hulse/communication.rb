module Hulse
  class Communication

    attr_reader :id, :date, :committee, :url, :text

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def to_s
      id
    end

    def self.executive
      comms = []
      doc = HTTParty.get("https://www.congress.gov/communications?q=%7B%22communication-code%22%3A%22PM%22%7D&pageSize=250")
      html = Nokogiri::HTML(doc.parsed_response)
      (html/:ol/:li).each do |row|
        comms << create(row)
      end
      comms
    end

    def self.create(row)
      self.new(id: row.children[3].children[0].text,
        date: Date.parse(row.children[3].children[1].text.split[1]),
        committee: row.children[3].children[1].text.split[3] + ' ' + row.children[3].children[1].text.split[4],
        url: (row/:h2).first.children.find(:a).first['href'],
        text: row.children[4].text.strip
      )
    end


  end
end
