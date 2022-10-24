# OhMyGlob

When listing files using glob wildcard syntax, it is possible for files that match the provided pattern to silently not be returned because your user does not have permission to list the contents one or more of those files ancestor directories.

`OhMyGlob` provides a drop-in replacement for Ruby's `Dir::glob` and a command-line tool that will report trouble on a glob path.

***CAVEAT: this project is not yet API-stable.***

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'oh_my_glob'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oh_my_glob

## Usage: Command Line

This gem has an executable `exe/oh_my_glob` that can be used to detect issues with discovering files.

It takes two arguments:
 - a required glob expression (hint: use single-quotes to prevent your shell from pre-expanding the glob)
 - optional comma-delimited flags

When there are no issues, it will list all discoverable files

> ~~~
> ╭─{ yaauie@maybe:~/src/yaauie/oh_my_glob (✔ main) }
> ╰─●  exe/oh_my_glob '/tmp/files/**/{1,2,3}.json' EXTGLOB,NOESCAPE
> /tmp/files/foodle/bar/baz/3.json
> /tmp/files/2.json
> [success]
> ~~~

When your glob could potentially match files that your user does not have permission to see, it will report those issues and exit with an error code.

> ~~~
> ╭─{ yaauie@maybe:~/src/yaauie/oh_my_glob (✔ main) }
> ╰─○ chmod 000 /tmp/files/foo/bar # remove all permission for everyone
> [success]
> ~~~
> ~~~
> ╭─{ yaauie@maybe:~/src/yaauie/oh_my_glob (✔ main) }
> ╰─●  exe/oh_my_glob '/tmp/files/**/{1,2,3}.json' EXTGLOB,NOESCAPE
> WARN: the provided glob pattern may be unable to discover one or more files {:pattern=>#<Pathname:/tmp/files/**/{1,2,3}.json>, :flags=>"EXTGLOB,NOESCAPE", :user=>"yaauie:(_lpadmin,_appserverusr,admin,_appserveradm)"}
> WARN: failed to list the contents of `/tmp/files/foo/bar` whose permissions are `40000 yaauie:staff`; this directory matches the partial glob `/tmp/files/**`, and files matching the remaining glob `**/{1,2,3}.json` may be missing from discovery
> [error: 17]
> ~~~

## Usage: Ruby Code

`OhMyGlob::each_file` is a drop-in replacement for `Dir.glob` that _ALWAYS_ attempts to detect trouble and reports it to `$stderr`:

~~~ ruby
require 'oh_my_glob'

# Dir.glob(my_glob_path) { |file_path| puts file_path }
OhMyGlob.each_file (my_glob_path) { |file_path| puts file_path }
~~~

If you intend to list the same glob path repeatedly and don't want to run the report for every single file listing, you may benefit from instantiating an `OhMyGlob::Globber` with your own configuration:

~~~ ruby
require 'oh_my_glob/globber'

my_logger = Logger.new
globber = OhMyGlob::Globber.new(my_glob_path,
                                %w{EXTGLOB DOTMATCH},
                                logger: my_logger,
                                report: %w{FIRST_RUN STALE(300)})

loop do
  my_logger.debug 'beginning discovery...'
  globber.each_file do |file_path|
    puts file_path
  end
  sleep(300)
end
~~~

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yaauie/oh_my_glob. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OhMyGlob project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/oh_my_glob/blob/master/CODE_OF_CONDUCT.md).
