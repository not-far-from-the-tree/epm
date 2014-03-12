module EventsHelper

  def date(datetime)
    datetime.strftime '%B %e %Y'
  end

  def time(datetime)
    datetime.strftime('%l:%M %p').strip
  end

  def month_calendar(events)
    content_tag 'section', class: 'month_calendar' do
      # calls method from simple_calendar gem with particular options
      options = {
        time_selector: 'start',
        class: nil,
        prev_text: '« previous',
        next_text: 'next »'
      }
      if can? :create, Event
        add_link = lambda{ |date| link_to '+', new_event_path(start_day: date), class: 'add', title: 'add event on this day' }
        options[:empty_date] = add_link
        options[:not_empty_date] = add_link
      end
      calendar events, options do |event|
        yield(event)
      end
    end
  end

end