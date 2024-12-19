source "https://rubygems.org"

gem "blueprinter" # JSON API serialization
gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb
gem "icalendar" # Enables support for iCalendar [https://github.com/icalendar/icalendar]
gem "importmap-rails" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "kamal", require: false # Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "nanoid" # Use nanoid for unique IDs [https://github.com/ruby-nanoid/nanoid]
gem "propshaft" # The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "puma", ">= 5.0" # Use the Puma web server [https://github.com/puma/puma]
gem "rails", "~> 8.0.1" # Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "slim-rails" # Use slim as the templating engine
# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "sqlite3", ">= 2.1" # Use sqlite3 as the database for Active Record
gem "stimulus-rails" # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "tailwindcss-rails" # Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "thruster", require: false # Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "tzinfo-data", platforms: %i[ windows jruby ] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem

group :development, :test do
  gem "brakeman", require: false # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude" # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "rubocop-rails-omakase", require: false # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
end

group :development do
  gem "annotaterb" # Annotate Rails models [https://github.com/ctran/annotate_models]
  gem "web-console" # Use console on exceptions pages [https://github.com/rails/web-console]
end

group :test do
  gem "capybara" # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "factory_bot_rails" # Use factory_bot for fixtures [https://github.com/thoughtbot/factory_bot_rails]
  gem "faker" # Use faker for generating fake data [https://github.com/faker-ruby/faker]
  gem "rspec-rails" # Use RSpec for unit testing [https://github.com/rspec/rspec-rails]
  gem "selenium-webdriver" # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
end

gem "bcrypt", "~> 3.1"
