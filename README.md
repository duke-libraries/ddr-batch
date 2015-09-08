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

### Log4r

#### Application.rb

Add the following lines to `config\application.rb` if they are not already there:

```ruby
require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/datefileoutputter'
include Log4r
```

#### Configuration

`Ddr::Batch::BatchProcessor` expects a Log4r configuration file at `config\log4r_batch_processor.yml`.

##### Example

```yaml
log4r_config:
    loggers:
        - name      : batch_processor
          level     : DEBUG
          trace     : 'false'
          outputters:
            - logfile
    outputters:
        - type      : StdoutOutputter
          name      : stdout
          level     : DEBUG
          formatter :
            date_pattern: '%F %T.%L'
            pattern     : '%d %l: %m'
            type        : PatternFormatter
        - type        : FileOutputter
          name        : logfile
          trunc       : 'false'
          filename    : "#{LOG_FILE}"
          formatter   :
            date_pattern: '%F %T.%L'
            pattern     : '%d %l: %m'
            type        : PatternFormatter
```

### Migrations

Install the ddr-batch migrations:

`rake ddr_batch:install:migrations`

then

`rake db:migrate`

`rake db:test:prepare`
