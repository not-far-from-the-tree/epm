class Tree < ActiveRecord::Base


  before_validation :check_species
  before_validation :check_user
  #before_validation :calculate_height

  strip_attributes

  belongs_to :owner, class_name: "User"
  belongs_to :submitter, class_name: "User"
  has_many :event_trees
  has_many :events, :through => :event_trees
  accepts_nested_attributes_for :owner

  acts_as_mappable through: :owner

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

  def self.closest(origin, ids, page)
    @page = 1
    if page.present? && page.to_i > 1
      @page = page.to_i
    end
    @trees = Tree.joins(:owner).by_distance(:origin => origin).where.not({'trees.id' => ids}).page(@page).per(10)
  end

  scope :search, ->(q) {
    db = Rails.configuration.database_configuration[Rails.env]["adapter"]
    like = db == 'postgresql' ? 'ILIKE' : 'LIKE'
    joins(:owner).where("trees.subspecies #{like} ? OR trees.species #{like} ? OR users.address #{like} ?", "%#{q}%", "%#{q}%", "%#{q}%")
  }

  private

  def check_user
    # first, check if anything has changed
    if self.owner.changed?
      # check if the name has changed, if so, create a new user
      if (self.owner.fname_changed? || self.owner.lname_changed?) && self.owner.email_changed?
        new_user_hash = self.owner.attributes
        new_user_hash.delete('id')
        new_user_hash['password'] = Devise.friendly_token.first(8)
        new_user = User.create(new_user_hash)
        self.submitter_id = self.owner.id
        self.owner_id = new_user.id
      end
    end
  end
end
