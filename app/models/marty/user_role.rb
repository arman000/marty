class Marty::UserRole < Marty::Base
  validates_uniqueness_of :user_id, scope: [:role]
  validates_presence_of :user_id, :role

  belongs_to :user
end
