class Marty::Diagnostic::Aws::Ec2Instance < Marty::Aws::Request
  attr_reader :tag,
              :nodes,
              :instances

  class InstancesSet
    STATES = [
      :pending, :running, :shutting_down, :terminated, :stopping, :stopped
    ].freeze

    attr_reader *STATES

    def get_state(instances, state)
      instances.map do |i|
        i.except('state') if i['state']['name'] == state
      end.compact
    end

    def initialize(instances)
      STATES.each do |s|
        instance_variable_set("@#{s}", get_state(instances, s.to_s))
      end
    end
  end

  def initialize
    super
    @service   = 'ec2'
    @tag       = get_tag
    @instances = InstancesSet.new(get_instances)
    @nodes     = get_private_ips
  end

  private

  def ec2_request(action, params = {})
    resp = request({ action: action }, params)
    parsed = Hash.from_xml(resp)

    # check AWS response for errors
    error = parsed.dig('Response', 'Errors', 'Error')
    raise Marty::Diagnostic::Aws::Error.new(action, error) if error

    action_resp = parsed["#{action}Response"]
    raise Marty::Diagnostic::Aws::Error.new(action, parsed) unless action_resp

    action_resp
  end

  def get_tag
    action = 'DescribeTags'
    params = { 'Filter.1.Name' => 'resource-id',
              'Filter.1.Value.1' => get_instance_id,
              'Filter.2.Name'    => 'key',
              'Filter.2.Value.1' => 'Name' }

    action_resp = ec2_request(action, params)
    tag = action_resp.dig('tagSet', 'item', 'value')
    raise Marty::Diagnostic::Aws::Error.new(action, action_resp) unless tag

    tag
  end

  def get_instances
    params = { 'Filter.1.Name' => 'tag-value',
              'Filter.1.Value.1' => @tag }

    resp = ec2_request('DescribeInstances', params)

    instances = ensure_resp(
      ['reservationSet', 'item', 'instancesSet', 'item'],
      resp
    ).flat_map do |i|
      {
        'id'    => i['instanceId'],
        'ip'    => i['privateIpAddress'],
        'state' => i['instanceState'],
      }
    end
  end

  def get_private_ips
    @instances.running.map { |i| i['ip'] }.compact
  end
end
