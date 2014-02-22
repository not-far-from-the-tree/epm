class Role < ActiveRecord::Base

  validates :user_id, :name, presence: true

  belongs_to :user

  enum name: [:admin, :coordinator, :participant]

end