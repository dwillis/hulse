module Hulse
  class HouseVote
    
    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end    
    
    
    
  end
end
