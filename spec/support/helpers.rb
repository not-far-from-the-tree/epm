module Helpers

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def map_points
    all('.map .leaflet-marker-icon').length
  end

  def run_task(task)
    require 'rake'
    rake = Rake::Application.new
    Rake.application = rake
    rake.init
    rake.load_rakefile
    rake[task].invoke
  end

end