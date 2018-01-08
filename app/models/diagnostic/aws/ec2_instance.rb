class Diagnostic::Aws::Ec2Instance
  attr_reader :id, :doc, :role, :creds, :version, :host, :tag, :nodes

  # aws reserved host used to get instance meta-data
  META_DATA_HOST = '169.254.169.254'

  def self.is_aws?
    response = get("http://#{META_DATA_HOST}") rescue nil
    response.present?
  end

  def initialize
    @id      = get_instance_id
    @doc     = get_document
    @role    = get_role
    @creds   = get_credentials
    @host    = "ec2.#{@doc['region']}.amazonaws.com"
    @version = '2016-11-15'
    @tag     = get_tag
    @nodes   = get_private_ips
  end

  private
  def self.get url
    uri = URI.parse(url)
    request = Net::HTTP.new(uri.host, uri.port)
    request.read_timeout = request.open_timeout = ENV['DIAG_TIMEOUT'] || 5
    request.start {|http|
      http.get(uri.to_s)
    }.body
  end

  def query_meta_data query
    self.class.get("http://#{META_DATA_HOST}/latest/meta-data/#{query}/")
  end

  def query_dynamic query
    self.class.get("http://#{META_DATA_HOST}/latest/dynamic/#{query}/")
  end

  def get_instance_id
    query_meta_data('instance-id').to_s
  end

  def get_role
    query_meta_data('iam/security-credentials').to_s
  end

  def get_credentials
    JSON.parse(query_meta_data("iam/security-credentials/#{@role}"))
  end

  def get_document
    JSON.parse(query_dynamic('instance-identity/document'))
  end

  def ec2_request action, params = {}
    default = {
      'Action' => action,
      'Version' => @version
    }

    url = "https://#{@host}/?" +
          (default + params).map{|a, v| "#{a}=#{v}"}.join('&')

    sig = Aws::Sigv4::Signer.new(service:           'ec2',
                                 region:            @doc['region'],
                                 access_key_id:     @creds['AccessKeyId'],
                                 secret_access_key: @creds['SecretAccessKey'],
                                 session_token:     @creds['Token'])
    signed_url = sig.presign_url(http_method:'GET', url: url)

    http = Net::HTTP.new(@host, 443)
    http.use_ssl = true
    Hash.from_xml(Net::HTTP.get(signed_url))["#{action}Response"]
  end

  def get_tag
    params = {'Filter.1.Name'    => 'resource-id',
              'Filter.1.Value.1' => get_instance_id,
              'Filter.2.Name'    => 'key',
              'Filter.2.Value.1' => 'Name'}
    ec2_request('DescribeTags', params)['tagSet']['item']['value']
  end

  def get_instances
    params = {'Filter.1.Name'    => 'tag-value',
              'Filter.1.Value.1' => @tag}
    ec2_request('DescribeInstances', params)
  end

  def get_private_ips
    get_instances['reservationSet']['item'].map{
      |i|
      item = i['instancesSet']['item']
      item.is_a?(Array) ? item.map{|i| i['privateIpAddress']} :
        item['privateIpAddress']
    }.flatten
  end
end