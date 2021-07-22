source "https://rubygems.org"

gem "bundler", ">= 2.0.1"

gem "rails", "~> 6.1.4"

# Database
gem "mysql2" # needed for migration of legacy data
gem "pg", "~> 1.1"

# Assets
gem "bootstrap-datepicker-rails"
gem "bootstrap-sass"
gem "coffee-rails", "~> 5.0.0"
gem "font-awesome-rails"
gem "fullcalendar-rails"
gem "jquery-rails"
gem "momentjs-rails"
gem "rails-backbone"
gem "select2-rails"
gem "strip_attributes", "< 2.0"
gem "therubyracer", platforms: :ruby
gem "uglifier", ">= 1.3.0"
gem "uri-js-rails" # URI manipulation

# File attachments
gem "carrierwave", "~> 2.1"
gem "fog-aws"
gem "mini_magick", ">= 4.9.4"

# Authentication / Authorization
gem "devise"
gem "pundit"
gem "rolify"

gem "slim", "~> 4.1" # Slim template language

# Jobs and tasks
gem "daemons"
gem "sidekiq"

# Internationalization
gem "devise-i18n"
gem "i18n-js", ">= 3.0.0.rc11"
gem "rails-i18n"
gem "route_translator", "~> 10.0"

# Model hierarchical data
gem "closure_tree", "~> 7.3"

# Tables
gem "font-awesome-sass", "~> 5.12"
gem "jquery-ui-rails"

# We are using this fork because the original gem is no longer maintained. This fork seems to be where
# most of the activity is happening in recent years. patricklindsay's fork has also been active,
# but this one is the only one I could find that works with Rails 6.1
gem "wice_grid", git: "https://github.com/kreintjes/wice_grid.git", branch: "fix/all"

gem "active_model_serializers" # Generating JSON data
gem "addressable" # URL handling
gem "amoeba" # Easy cloning of active record objects
gem "attribute_normalizer" # For normalizing model attribs
gem "awesome_print"
gem "chroma" # Color manipulation
gem "chronic" # For parsing human readable dates
gem "exception_notification" # Send email on errors
gem "goldiloader" # Eager loading
gem "gon" # Passing controller data to JS
gem "nokogiri", "1.11.4"
gem "quickbooks-ruby", "= 1.0.10"
gem "remotipart", "~> 1.2" # File uploads for remote: true forms
gem "sassc-rails"
gem "scout_apm"
gem "simple_form"
gem "sprockets", "~> 3.7.2"
gem "summernote-rails", "~> 0.8.10.0" # Text editor
gem "whenever", "~> 0.9", require: false # Improved syntax for creating cron jobs

# Watches for inefficient queries and recommends eager loading
gem "bullet"

group :development, :test do
  # Load environment variables from .env file in development
  gem "dotenv-rails"

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug"
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"

  # Report number of queries in server log
  gem "sql_queries_count"

  # Better console printing
  # gem "awesome_print"
  gem "hirb"

  # development server
  gem "puma"

  # Specs and Test Coverage
  gem "capybara", "~> 3.0"
  gem "database_cleaner", "~> 1.5"
  gem "factory_bot_rails"
  gem "faker"
  gem "letter_opener"
  gem "poltergeist", "~> 1.0"
  gem "pundit-matchers"
  gem "rspec-rails"
  gem "selenium-webdriver", "~> 3.0"
  gem "simplecov"
  gem "webdrivers", "~> 4.0"

  # Dump data to Rails commands
  gem "seed_dump"
end

group :development do
  # Improve error screens
  gem "better_errors"
  gem "binding_of_caller"

  # Fix db schema conflicts
  gem "fix-db-schema-conflicts"

  # Linting
  gem "rubocop", "1.5.2" # Exact version to support what Hound has
  gem "rubocop-rails", "~> 2.9.1"
  gem "rubocop-rspec", require: false

  # Deployment
  gem "capistrano", "~> 3.11.0"
  gem "capistrano-passenger"
  gem "capistrano-rails", "~> 1.1"
  gem "capistrano-rbenv", "~> 2.1"
  gem "capistrano-sidekiq", require: false

  # Auto reload browser
  gem "guard-livereload", "~> 2.5", require: false
  gem "rack-livereload"

  gem "term-ansicolor", "~> 1.3.0"

  # Mask password at command line
  gem "highline"
end

group :development, :doc do
  gem "rails-erd"
end

group :test do
  # For GH action
  gem "rspec-github", require: false
end
