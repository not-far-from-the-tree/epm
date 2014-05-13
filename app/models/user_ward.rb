class UserWard < ActiveRecord::Base

  belongs_to :user
  belongs_to :ward
  validates :user_id, uniqueness: { scope: :ward }

end