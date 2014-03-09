module EventsHelper

  def date(datetime)
    datetime.strftime '%B %e %Y'
  end

  def time(datetime)
    datetime.strftime('%l:%M %p').strip
  end

end