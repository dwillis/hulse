require 'test_helper'
require_relative '../lib/hulse'

module Hulse
  class SponsorshipTest < Minitest::Test

    def setup
      @sponsorships = Sponsorship.member_details("https://www.congress.gov/member/joyce-beatty/B001281", "114")
    end

    def test_sponsored_bills
      assert_equal @sponsorships.select{|s| s.description == 'sponsored'}.size, 15
      assert_equal @sponsorships.select{|s| s.description == 'cosponsored'}.size, 275
    end

  end
end
