require 'test_helper'
require_relative '../lib/hulse'

module Hulse
  class HouseVoteTest < Minitest::Test

    def setup
      @hv = HouseVote.find(2015,582)
      @sv = HouseVote.find(2015,581)
    end

    def test_bill_url
      assert_equal @hv.bill_url, "https://www.congress.gov/bill/114th-congress/house-bill/1853"
      assert_equal @sv.bill_url, nil
    end

  end
end
