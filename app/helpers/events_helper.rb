module EventsHelper

  def date(datetime)
    datetime.strftime "%B %d %Y, %l:%M %p"
  end

end