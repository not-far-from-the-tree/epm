class Role < ActiveRecord::Base

  validates :name, presence: true

  belongs_to :user

  enum name: [:admin, :coordinator, :participant]
  validates :name, uniqueness: { scope: :user_id }

  default_scope { order :name }

  before_destroy do |role|
    response = true
    if role.name == 'admin' && User.admins.count == 1
      errors.add :base, 'Admin role cannot be removed if there are no other admins'
      response = false
    end
    response
  end

end