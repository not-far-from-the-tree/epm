source 'https://rubygems.org'

gem 'rails', "4.1.0.rc2"

gem 'strip_attributes'

# assets
gem 'sass-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'jquery-ui-rails'

# authorization and authentication
gem 'devise'
gem 'cancancan'

gem 'configurable_engine' # site-wide config

gem 'icalendar'

# geo stuff
gem 'geokit-rails'
gem 'geokit-nominatim'
gem 'leaflet-rails'

# ui
gem 'rinku' # URL auto-linking
gem 'simple_calendar'
gem 'kaminari' # pagination

group :production do
  # Heroku
  gem 'pg'
  gem 'rails_12factor'

  # Dreamhost Shared Hosting
  # gem 'mysql2'
  # gem 'fcgi'
  # gem 'therubyracer'
end

group :development, :test do
  gem 'pg'

  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'letter_opener'
end

group :test do
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'database_cleaner'
end