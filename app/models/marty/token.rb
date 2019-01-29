class Marty::Token < Marty::Base
  belongs_to :user
  validates_uniqueness_of :value

  before_create :delete_previous_tokens, :generate_new_token

  # @@validity_time = 1.day

  def generate_new_token
    self.value = Token.generate_token_value
  end

  # # Return true if token has expired
  # def expired?
  #   return Time.now > self.created_on + @@validity_time
  # end

  private

  def self.generate_token_value
    SecureRandom.hex(20)
  end

  # Removes obsolete tokens
  def delete_previous_tokens
    if user && !Marty::Util.db_in_recovery?
      Token.delete_all(['user_id = ?', user.id])
    end
  end
end
