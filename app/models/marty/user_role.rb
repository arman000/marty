class Marty::UserRole < Marty::Base
  validates :user_id, uniqueness: { scope: [:role] }
  validates :user_id, :role, presence: true

  belongs_to :user
end
