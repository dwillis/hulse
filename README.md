# Hulse

Hulse is a Ruby gem for accessing raw data and information published by and about the U.S. Congress. It works using Ruby 1.9.3, 2.0, 2.1 and 2.2. It is not a wrapper for existing non-governmental APIs of congressional information. Instead, it loads, parses and scrapes official sources.

Hulse can be used to get House and Senate roll call votes from the official sources on [house.gov](http://clerk.house.gov/evs/2013/index.asp) and [senate.gov](http://www.senate.gov/pagelayout/legislative/a_three_sections_with_teasers/votes.htm).

Hulse has two vote classes, `HouseVote` and `SenateVote`, which create Ruby objects using the XML attributes available from roll call vote data (voice votes are not covered by Hulse or available as data from official sources). Hulse makes a few changes, renaming some attributes for clarity and consistency, and collapsing each House vote's date and time into a single datetime attribute. Otherwise it does not alter the original data.

`HouseVote` and `SenateVote` have different attributes due to parliamentary conventions and the presence or absence of data in one chamber or the other. Senators are uniquely identified by a `lis_member_id`; House members are uniquely identified by a `bioguide_id` beginning in 2003. Prior to 2003, there is no unique ID for House members, but using a combination of name, state and political party one can be manufactured. House member attributes also include an `unaccented_name` and a `name` attribute that may contain accent characters.

Hulse also has two member classes, `HouseMember` and `SenateMember`, which create Ruby objects using the XML made available by the Clerk of the House and the Secretary of the Senate. House members have some basic information, including the unique `bioguide_id`, along with office details and committee and subcommittee assignment data. For vacant seats, information on the seat's previous occupant is available. Senate members have less information, but their data includes the Senate class and the URLs of their websites and email forms.

Hulse has two other classes, `HouseFloor` and `Record`. The former provides a wrapper to [XML data on floor activity](http://clerk.house.gov/floorsummary/floor.aspx?day=20150729) published by the Clerk of the House, including timestamps and descriptions. The `Record` class provides a basic wrapper to the [Congressional Record](https://www.congress.gov/congressional-record), the daily listing of activities by the House and Senate, as well as some methods for accessing specific portions of it, particularly the titles and permalinks of articles.

Hulse is named for [Carl Hulse](https://www.nytimes.com/learning/students/ask_reporters/Carl_Hulse.html), a longtime congressional correspondent for The New York Times.

## Installation

Add this line to your application's Gemfile:

    gem 'hulse'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hulse

## Usage

For both House and Senate votes, pass the year and roll call number into the `find` class method:

```ruby
2.0.0p353 :001 > require 'hulse'
2.0.0p353 :002 > include Hulse
2.0.0p353 :003 > hv = HouseVote.find(2013, 628)
2.0.0p353 :004 > hv.question
 => "On Agreeing to the Amendment"
2.0.0p353 :005 > hv.vote_count
  => {:yea_total=>157, :nay_total=>258, :present_total=>0, :not_voting_total=>16}
```

Be aware that in 2012, there were 5 House votes that occurred on Jan. 1, 2013. These are considered "2012" votes by [the Clerk of the House](http://clerk.house.gov/evs/2012/index.asp), so use 2012 as the year for these.

For Senate votes, you can grab a year's SenateVote objects (with a limited set of attributes) by using the `summary` method:

```ruby
2.0.0p353 :006 > senate_2013 = SenateVote.summary(2013)
2.0.0p353 :007 > senate_2013.first
=> <Hulse::SenateVote:0x000001017f0d58 @congress=113, @session=1, @year=2013, @vote_number="00291", @vote_date=<Date: 2013-12-20 ((2456647j,0s,0n),+0s,2299161j)>, @issue="PN921", @question="On the Cloture Motion", @vote_result="Agreed to", @vote_count={:yeas=>"59", :nays=>"34"}, @vote_title="Motion to Invoke Cloture on the Nomination of Janet L. Yellen to be Chairman of the Board of Governors of the Federal Reserve System">
```
House and Senate members have a `current` class method that retrieves the latest XML data from the House and Senate websites and creates Ruby objects. The House file has more data, including vacancies, than the Senate file does.

```ruby
irb(main):003:> require 'hulse'
irb(main):003:0> members = Hulse::HouseMember.current
irb(main):004:0> members.first
=> <Hulse::HouseMember:0x007fc6cb37f020 @bioguide_id="Y000033", @sort_name="YOUNG,DON", @last_name="Young", @first_name="Don", @middle_name=nil, @suffix=nil, @courtesy="Mr.", @official_name="Don Young", @formal_name="Mr. Young of Alaska", @party="R", @caucus_party="R", @state_postal="AK", @state_name="Alaska", @district="At Large", @district_code="AK00", @hometown="Fort Yukon", @office_building="RHOB", @office_room="2314", @office_zip="20515-0200", @phone="(202) 225-5765", @last_elected_date=#<Date: 2014-11-04 ((2456966j,0s,0n),+0s,2299161j)>, @sworn_date=#<Date: 2015-01-12 ((2457035j,0s,0n),+0s,2299161j)>, @committees=[{"comcode"=>"II00", "rank"=>"2"}, {"comcode"=>"PW00", "rank"=>"2"}], @subcommittees=[{"subcomcode"=>"II10", "rank"=>"2"}, {"subcomcode"=>"II13", "rank"=>"2"}, {"subcomcode"=>"II24", "rank"=>"1", "leadership"=>"Chairman"}, {"subcomcode"=>"PW05", "rank"=>"2"}, {"subcomcode"=>"PW07", "rank"=>"2"}, {"subcomcode"=>"PW12", "rank"=>"2"}], @is_vacant=false, @footnote=nil, @predecessor=nil, @vacancy_date=nil>
```

## Tests

Hulse uses `MiniTest` for development. To run the tests, do `rake test`.

## Authors

* [Derek Willis](https://github.com/dwillis)
* [Eric Mill](https://github.com/konklone)

## Contributing

1. Fork it ( http://github.com/dwillis/hulse/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
