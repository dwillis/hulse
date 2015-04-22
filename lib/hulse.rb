require 'httparty'
require 'oj'
require "hulse/version"
require "hulse/house_vote"
require "hulse/senate_vote"
require "hulse/house_member"

module Hulse
  class Utils

    # this function is more intuitive when you solve for the other side:
    # year = 1789 + (2 * (congress - 1))
    def self.congress_for_year(year)
      ((year.to_i + 1) / 2) - 894
    end

    def self.convert_year_to_congress_and_session(year)
      congress = congress_for_year year
      session = year.to_i.odd? ? 1 : 2
      return [congress, session]
    end


  end
end
