class Marty::HttpApiAuth < Marty::Base

  UNFETTERED_ACCESS_CHARS = [nil, '', '*']

  before_validation :generate_token

  validate :ensure_valid_schema
  validates :app_name, :token, presence: true

  private

  # Requires the `authorizations` field to follow a specific `schema`.
  # The authorizations field takes a list of hashes where each hash
  # contains path and method that CAN BE accessed.
  # i.e
  #    [
  #      {
  #        path: '/test/app',
  #        method: 'GET'
  #      },
  #      {...}
  #    ]
  # +path+ is the URL path and +method+ is the HTTP method you want to allow access to.
  #

  def ensure_valid_schema
    return true if UNFETTERED_ACCESS_CHARS.include?(authorizations)

    result = JSON::Validator.validate(schema, authorizations, list: true)
    errors.add(:base, 'invalid schema') if result == false
  end

  def schema
    {
      'type' => 'object',
      'required' => ['path', 'method'],
      'properties' => {
        'path' => { 'type' => 'string' },
        'method' => { 'type' => 'string' }
      }
    }
  end

  def generate_token
    return if token.present?

    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Marty::HttpApiAuth.exists?(token: random_token)
    end
  end
end
