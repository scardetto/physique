# physique

Beautiful builds for .NET

## Installation

Add this line to your application's Gemfile:

    gem 'physique'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install physique

## Usage

In your project's Rakefile:

```ruby
require 'physique'

Physique::Solution.new do |s|
  s.file = 'src/your-solution.sln'
end
```

To view the available `rake` tasks:

    $ rake --tasks

## Contributing

1. Fork it ( https://github.com/scardetto/physique/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
