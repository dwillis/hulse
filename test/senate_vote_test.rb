require 'test_helper'
require_relative '../lib/hulse'

module Hulse
  class SenateVoteTest < Minitest::Test

    def setup
      @sv = SenateVote.find(2015,291)
      @nv = SenateVote.find(2015,274)
    end

    def test_bill_url
      assert_equal @sv.bill_url, "https://www.congress.gov/bill/114th-congress/senate-bill/754"
      assert_equal @nv.bill_url, nil
    end

    def test_nomination
      assert_equal @nv.is_nomination_vote?, true
    end

  end
end
