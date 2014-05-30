class Ward < ActiveRecord::Base

  def active?
    (Configurable.active_wards || '').split(',').map{|w| w.to_i}.include? id
  end

end