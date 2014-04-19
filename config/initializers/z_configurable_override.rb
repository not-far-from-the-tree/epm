# filename is z_* as this causes an error when loaded before any initializer which uses this model, i.e. devise.rb

# overriding https://github.com/paulca/configurable_engine/blob/master/app/models/configurable.rb
# to remove the .sort from self.keys, so that they keep the sort order defined in the yaml file

class Configurable < ActiveRecord::Base

  def self.keys
    self.defaults.collect { |k,v| k.to_s }
  end

end