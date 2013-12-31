require "hulse/version"
require "hulse/house_vote"
require "hulse/senate_vote"
require 'httparty'
require 'oj'

module Hulse
  class Utils
    
    CONGRESSES = {
      2014 => 113,
      2013 => 113,
      2012 => 112,
      2011 => 112,
      2010 => 111,
      2009 => 111,
      2008 => 110,
      2007 => 110,
      2006 => 109,
      2005 => 109,
      2004 => 108,
      2003 => 108,
      2002 => 107,
      2001 => 107,
      2000 => 106,
      1999 => 106,
      1998 => 106,
      1997 => 105,
      1996 => 105,
      1995 => 104,
      1994 => 104,
      1993 => 103,
      1992 => 103,
      1991 => 102,
      1990 => 102,
      1989 => 101
    }
    
    def self.convert_year_to_congress_and_session(year)
      congress = CONGRESSES[year]
      session = year.odd? ? 1 : 2
      return [congress, session]
    end
    
    
  end
end
