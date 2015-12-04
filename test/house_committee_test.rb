require 'test_helper'
require_relative '../lib/hulse'

module Hulse
  class HouseCommitteeTest < Minitest::Test

    def setup
      @committees = HouseCommittee.current
    end

    def test_committee_name
      assert_equal @committees.detect{|c| c.code == 'AG00'}.name, 'Committee on Agriculture'
    end

  end
end
