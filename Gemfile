source 'https://rubygems.org'

gem 'rails', "4.1.0.rc1"

gem 'sass-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'turbolinks'

gem 'devise'

group :production do
  gem 'pg'
  gem 'rails_12factor'
end

# normally these are just used in development and test;
# included for production here as well as production now is a demo using demo data generated from factories
gem 'factory_girl_rails'
gem 'faker'

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails'
  gem "letter_opener"
end

group :test do
  gem 'capybara'
end