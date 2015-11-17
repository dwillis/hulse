require 'httparty'
require 'oj'
require 'nokogiri'
require 'htmlentities'
require "hulse/version"
require "hulse/record"
require "hulse/communication"
require "hulse/house_vote"
require "hulse/house_member"
require "hulse/house_floor"
require "hulse/senate_vote"
require "hulse/senate_member"
require "hulse/sponsorship"
require "active_support/core_ext/integer/inflections"

module Hulse
  class Utils


    def self.current_congress
      114
    end

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

    def self.bill_url(congress, bill_number)
      bill_title = bill_number.scan(/[A-Z]+/).join.upcase
      if bill_title == 'HR'
        bt = 'house-bill'
      elsif bill_title == 'HRES'
        bt = 'house-resolution'
      elsif bill_title == 'HJRES'
        bt = 'house-joint-resolution'
      elsif bill_title == 'S'
        bt = 'senate-bill'
      elsif bill_title == 'SRES'
        bt = 'senate-resolution'
      elsif bill_title == 'SJRES'
        bt = 'senate-joint-resolution'
      end
      bill_num = bill_number.scan(/\d/).join
      "https://www.congress.gov/bill/#{congress.to_i.ordinalize.to_s}-congress/#{bt}/#{bill_num}"
    end

  end
end
