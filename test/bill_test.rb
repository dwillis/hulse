require 'test_helper'
require_relative '../lib/hulse'

module Hulse
  class BillTest < Minitest::Test

    def setup
      @bill = Bill.scrape_bill("https://www.congress.gov/bill/113th-congress/house-bill/1206")
      @other_bill = Bill.scrape_bill("https://www.congress.gov/bill/113th-congress/house-bill/5784")
    end

    def test_bill_sponsor_details
      assert_equal @bill.sponsor_bioguide, "W000804"
      assert_equal @bill.sponsor_party, "R"
      assert_equal @bill.sponsor_state, "VA"
    end

    def test_bill_committees
      assert_equal @other_bill.committees, "House - Veterans' Affairs"
      assert_equal @other_bill.latest_action_date, Date.parse("2014-12-23")
    end

    def test_bill_actions
      assert_equal @other_bill.actions.size, 3
      assert_equal @other_bill.actions.first[:action_by], "House Veterans' Affairs"
    end

  end
end
