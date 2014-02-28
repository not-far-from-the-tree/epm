module ApplicationHelper

  def title(str)
    content_for :title, str
  end

  def clear
    content_tag 'div', nil, class: 'clearfix'
  end

end