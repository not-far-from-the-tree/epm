class Role < ActiveRecord::Base

  validates :user_id, :name, presence: true

  belongs_to :user

  enum name: [:admin, :coordinator, :participant]

  # validates :name, uniqueness: { scope: :user_id } # broken? https://github.com/rails/rails/issues/14172

end