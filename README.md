# ddr-batch

A Rails engine providing batch processing functionality for the Duke Digital Repository.

## Installation

Add to your application's Gemfile:

    gem 'ddr-batch'

and

    bundle install

## Configuration

### User model

Include `Ddr::Batch::User` in `app/models/user.rb`

```ruby
class User < ActiveRecord::Base

  # DO NOT REMOVE:
  # Blacklight::User
  # Ddr::Auth::User
  #
  include Ddr::Batch::BatchUser

end
```
