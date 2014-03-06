module ApplicationHelper

  def title(str)
    content_for :title, str
  end

  def clear
    content_tag 'div', nil, class: 'clearfix'
  end

  def start_cols
    '<div class="cols"><div class="colA">'.html_safe
  end
  def next_col
    '</div><div class="colB">'.html_safe
  end
  def end_cols
    "</div></div>#{clear}".html_safe
  end

end