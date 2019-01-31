class Marty::Aws::Base
  # this base class is used for instance information/credential acquisition

  # FIXME: should that be in public marty gem?
  # aws reserved host used to get instance meta-data
  META_DATA_HOST = '169.254.169.254'

  attr_reader :id,
              :doc,
              :role,
              :creds,
              :version,
              :host,
  def self.get url
    uri = URI.parse(url)
    req = Net::HTTP.new(uri.host, uri.port)
    req.read_timeout = req.open_timeout = ENV['AWS_REQUEST_TIMEOUT'] || 0.25
    req.start {|http| http.get(uri.to_s) }.body
  end

  def self.is_aws?
    # FIXME: hack to pass tests on CI
    return false if Rails.env.test?

    response = get("http://#{META_DATA_HOST}") rescue nil
    response.present?
  end

  def initialize
    @id            = get_instance_id
    @doc           = get_document
    @role          = get_role
    @creds         = get_credentials
    @version       = '2016-11-15'
  end

  def query_meta_data query
    self.class.get("http://#{META_DATA_HOST}/latest/meta-data/#{query}/")
  end

  def query_dynamic query
    self.class.get("http://#{META_DATA_HOST}/latest/dynamic/#{query}/")
  end

  private
  def get_instance_id
    query_meta_data('instance-id').to_s
  end

  def get_role
    query_meta_data('iam/security-credentials').to_s
  end

  def sym obj
    obj.each_with_object({}){|(k, v), h| h[k.underscore.to_sym] = v}
  end

  def get_credentials
    sym(JSON.parse(query_meta_data("iam/security-credentials/#{@role}")))
  end

  def get_document
    sym(JSON.parse(query_dynamic('instance-identity/document')))
  end
end
