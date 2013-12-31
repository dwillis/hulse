# Hulse

Hulse is a Ruby gem for accessing House and Senate roll call votes from the official sources on [house.gov](http://clerk.house.gov/evs/2013/index.asp) and [senate.gov](http://www.senate.gov/pagelayout/legislative/a_three_sections_with_teasers/votes.htm). It works using Ruby 1.9.3 and 2.0.0.

Hulse has two classes, `HouseVote` and `SenateVote`, which create Ruby objects using the XML attributes available from roll call vote data (voice votes are not covered by Hulse or available as data from official sources). Hulse makes a few changes, renaming some attributes for clarity and consistency, and collapsing each House vote's date and time into a single datetime attribute. Otherwise it does not alter the original data.

`HouseVote` and `SenateVote` have different attributes due to parliamentary conventions and the presence or absence of data in one chamber or the other. Senators are uniquely identified by a `lis_member_id`; House members are uniquely identified by a `bioguide_id` beginning in 2003. Prior to 2003, there is no unique ID for House members, but using a combination of name, state and political party one can be manfactured. House member attributes also include an `unaccented_name` and an `name` attribute that may contain accent characters.

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
1.9.3-p484> require 'hulse'
1.9.3-p484> include Hulse
1.9.3-p484> hv = HouseVote.find(2013, 628)
1.9.3-p484> hv.question
 => "On Agreeing to the Amendment"
 1.9.3-p484> hv.vote_count
  => {:yea_total=>157, :nay_total=>258, :present_total=>0, :not_voting_total=>16}
```

Be aware that in 2012, there were 5 House votes that occurred on Jan. 1, 2013. These are considered "2012" votes by [the Clerk of the House](http://clerk.house.gov/evs/2012/index.asp), so use 2012 as the year for these.

## Authors

* [Derek Willis](https://github.com/dwillis)

## Contributing

1. Fork it ( http://github.com/dwillis/hulse/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
