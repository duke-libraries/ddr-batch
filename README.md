# ddr-batch

A Rails engine providing batch processing functionality for the Duke Digital Repository.

## Installation

Add to your application's Gemfile:

    gem 'ddr-batch'

and

    bundle install

## Configuration

### User model

Include `Ddr::Batch::BatchUser` in `app/models/user.rb`.

```ruby
class User < ActiveRecord::Base

  # DO NOT REMOVE:
  # Blacklight::User
  # Ddr::Auth::User
  #
  include Ddr::Batch::BatchUser

end
```

### Ability class

Add `Ddr::Batch::BatchAbilityDefinitions` to the list of `ability_definitions`.

```ruby
class Ability < Ddr::Auth::Ability

  self.ability_definitions += [ Ddr::Batch::BatchAbilityDefinitions ]

end
```

### Migrations

Install the ddr-batch migrations:

`rake ddr_batch:install:migrations`

then

`rake db:migrate`

`rake db:test:prepare`
