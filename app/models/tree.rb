class Tree < ActiveRecord::Base
  acts_as_mappable

  before_validation :check_species
  before_validation :check_user
  #before_validation :calculate_height

  strip_attributes

  belongs_to :owner, class_name: "User"
  belongs_to :submitter, class_name: "User"
  has_many :event_trees
  has_many :events, :through => :event_trees
  accepts_nested_attributes_for :owner
  #accepts_nested_attributes_for :submitter
  #attr_accessor :fauxheight
  #attr_accessor :uom 
  attr_accessor :species_other

  # enum keep: [ "a 1/3 of the", "less than 1/3 of the", "no" ]
  enum keep: [ "yes", "abit", "no" ]
  enum height: [
    ">3",
    "2-3",
    "1-2",
    "<1"
  ]
  def self.height_labels
  {
    "> 3 storeys (> 9 metres, 30 feet)" => ">3",
    "2-3 storeys (20-30 feet, 6-9 metres)" => "2-3",
    "1 - 2 storeys (10-20 feet, 3-6 metres)" => "1-2",
    "< 1 storey (< 10 feet, 3 metres)" => "<1"
  }
  end

  def self.types
    ["Apple","Apricot","Cherry","Crabapple","Elderberry","Ginkgo","Grape","Mulberry","Pawpaw","Peach","Pear","Persimmon","Plum","Quince","Serviceberry"]
  end

  def check_species
    if self.species.blank? && self.species_other.present?
      self.species = self.species_other
    end
  end 

#  def calculate_height
#    h = self.fauxheight.to_f
#    if self.uom == "feet" 
#      self.height = h * 0.3048
#    elsif self.uom == "stories"
#      # according to wikipedia, there are about 3 metres per story
#      self.height = h * 3
#    else
#      self.height = h  
#    end
#  end 

  def closest 
    @add = true
    @page = 1
    if params['page'].present? && params['page'].to_i > 1
      @page = params['page'].to_i
    end
    @trees = Tree.joins(:user).by_distance(:origin => '146 Donlands, Toronto, ON').where.not({'trees.id' => params['ids']})
    render :_list, layout: false
  end

  private

  def check_user
    puts "START CHECK USER"
    puts self.to_yaml
    # puts self.user.to_yaml
    puts self.owner.changes
    # first, check if anything has changed
    puts self.owner.changed?
    if self.owner.changed?
      # check if the name has changed, if so, create a new user
      if (self.owner.fname_changed? || self.owner.lname_changed?) && self.owner.email_changed?
        new_user_hash = self.owner.attributes
        new_user_hash.delete('id')
        new_user_hash['password'] = Devise.friendly_token.first(8)
        puts new_user_hash.to_yaml
        new_user = User.create(new_user_hash)
        puts new_user.to_yaml
        puts new_user.errors.full_messages
        puts new_user.id
        self.submitter_id = self.owner.id
        self.owner_id = new_user.id
      end
    end
  end
end
