# sequel-xtdb

[![Gem Version](https://badge.fury.io/rb/sequel-xtdb.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/sequel-xtdb)

Adapter to connect to [XTDB](https://docs.xtdb.com/) v2 using [Sequel](https://sequel.jeremyevans.net/).

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add sequel-xtdb
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install sequel-xtdb
```

## Usage

Shortcut to happiness:
```ruby
# Get a Ruby console using the sequel CLI
$ sequel 'xtdb://localhost:5432/xtdb'

# ..or from repl/your project
DB = Sequel.connect("xtdb://localhost:5432/xtdb")

# then
irb(main)> DB << "insert into products(_id, name, price) values(1, 'Spam', 1000), (2, 'Ham', 1200)"
irb(main)> DB["select * from products"].all
=> [{:_id=>2, :name=>"Ham", :price=>1200}, {:_id=>1, :name=>"Spam", :price=>1100}]
```

### time-travel

_these examples use the [activesupport time helpers](https://api.rubyonrails.org/classes/ActiveSupport/Duration.html)_

```ruby
DB = Sequel.connect("xtdb://localhost:5432/xtdb")

# get a dataset (ie query)
users = DB[:users]
ds1, ds2 = users.as_of(valid: 2.days.ago), users.as_of(valid: 2.days.from_now)

# expect empty
ds1.all
ds1.insert(_id: 1, name: "James")

# expect a user
ds1.as_of(valid: 2.days.ago).all

# add to future
ds2.insert(_id: 2, name: "Jeremy")

# expect only James
users.all
# expect both James and Jeremy
ds2.as_of(valid: 2.days.from_now).all
```


## Status

Very early days :)  
Currently it's essentially the postgres-adapter with support for a xtdb-scheme url.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

You can also run `bin/console [xtdb-url]` for an interactive prompt that will allow you to experiment. The script will pick up on env-var `XTDB_URL`, though the argument takes precedence. The console-script sets up (query-)logging.  

Speaking of logging: best to start the XTDB docker container with debug-logging:
```
docker run -it --pull=always -e XTDB_LOGGING_LEVEL=debug -v $PWD/tmp/db:/var/lib/xtdb -p 6543:3000 -p 5432:5432 ghcr.io/xtdb/xtdb:nightly
```

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eval/sequel-xtdb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
