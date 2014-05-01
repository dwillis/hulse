require 'test_helper'
require_relative '../lib/hulse'

module Hulse
  class UtilsTest < Minitest::Test
    def test_congress_for_year
      assert_equal 101, Utils.congress_for_year(1990)
      assert_equal 106, Utils.congress_for_year('2000')
      assert_equal 6, Utils.congress_for_year('1800')
      assert_equal 1, Utils.congress_for_year('1789')

      # TODO: probably not what is expected
      assert_equal -4, Utils.congress_for_year('1780')
    end

    def test_convert_year_to_congress_and_session
      congress, session = Utils.convert_year_to_congress_and_session(1990)
      assert_equal 101, congress
      assert_equal 2,   session

      congress, session = Utils.convert_year_to_congress_and_session('1789')
      assert_equal 1, congress
      assert_equal 1, session

      # TODO: probably not what is expected
      congress, session = Utils.convert_year_to_congress_and_session('1780')
      assert_equal -4, congress
      assert_equal 2, session
    end
  end
end