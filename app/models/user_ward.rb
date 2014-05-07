class UserWard < ActiveRecord::Base

  belongs_to :user
  belongs_to :ward

end