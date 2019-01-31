class Marty::Diagnostic::Aws::Ec2Instance < Marty::Aws::Request
  attr_reader :tag,
              :nodes,
              :instances

  class InstancesSet
    STATES = [
      :pending, :running, :shutting_down, :terminated, :stopping, :stopped
    ].freeze

    attr_reader *STATES

    def get_state instances, state
      instances.map do
        |i|
        i.except('state') if i['state']['name'] == state
      end.compact
    end

    def initialize instances
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
  def ec2_request action, params = {}
    resp = request({action: action}, params)
    Hash.from_xml(resp)["#{action}Response"]
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
    @instances.running.map{|i| i['ip']}.compact
  end
end
