# Event-Participant Manager

## Deploying
Things to modify
* Gemfile :production group
* config/database.yml production
* config/environments/production.rb , the mailer config options
Run `whenever -w` to create the cron file for reminder emails


## Testing

Test by running 'rspec'.