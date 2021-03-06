require 'test_helper'
require_relative '../lib/hulse'

module Hulse
  class BillTest < Minitest::Test

    def setup
      @bill = Bill.scrape_bill("https://www.congress.gov/bill/113th-congress/house-bill/1206")
      @other_bill = Bill.scrape_bill("https://www.congress.gov/bill/114th-congress/house-bill/22")
      @third_bill = Bill.scrape_bill("https://www.congress.gov/bill/113th-congress/house-bill/5890")
      @fourth_bill = Bill.scrape_bill("https://www.congress.gov/bill/113th-congress/senate-bill/311")
      @fifth_bill = Bill.scrape_bill("https://www.congress.gov/bill/113th-congress/senate-bill/456")
    end

    def test_bill_sponsor_details
      assert_equal @bill.sponsor_bioguide, "W000804"
      assert_equal @bill.sponsor_party, "R"
      assert_equal @bill.sponsor_state, "VA"
    end

    def test_bill_committees
      assert_equal @other_bill.committees, "House - Ways and Means | Senate - Finance"
      assert_equal @other_bill.latest_action_date, Date.parse("2015-12-02")
    end

    def test_bill_actions
      assert_equal @other_bill.actions.size, 481
      assert_equal @bill.actions.size, 24
      assert_equal @third_bill.actions.size, 3
    end

    def test_related_bills
      assert_equal @bill.related_bills.size, 7
      assert_equal @third_bill.related_bills.size, 0
    end

    def test_amendments
      assert_equal @other_bill.amendments.size, 379
      assert_equal @fifth_bill.amendments.size, 0
    end

    def test_cosponsors
      assert_equal @other_bill.cosponsors.size, 118
    end

    def test_party_cosponsors
      assert_equal @bill.bipartisan_cosponsors?, true
      assert_equal @bill.democratic_cosponsors.size, 1
    end

    def test_committee_actions
      assert_equal @fourth_bill.committee_actions.last[:committee], "House Natural Resources Subcommittee on Public Lands and Environmental Regulation"
    end

    def test_policy_area
      assert_equal @fifth_bill.policy_area, "Education"
    end

  end
end
