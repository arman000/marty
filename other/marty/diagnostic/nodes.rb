require_relative 'aws/ec2_instance'

module Marty::Diagnostic; class Nodes < Base
  diagnostic_fn aggregatable: false do
    begin
      pg_nodes = Node.get_nodes.sort
    rescue => e
      next error(e.message)
    end

    next pg_nodes.join("\n") unless
      Marty::Diagnostic::Aws::Ec2Instance.is_aws?

    begin
      instance_data = Marty::Diagnostic::Aws::Ec2Instance.new
    rescue => e
      next error(pg_nodes.join("\n") +
                 "\nAws Communication Error: #{e.message}")
    end

    begin
      a_nodes = instance_data.nodes.sort
      next pg_nodes.join("\n") if a_nodes == pg_nodes

      # generate instance information when there is an issue
      # between aws and postgres
      instances = instance_data.instances
      { 'nodes' => error("There is a discrepancy between nodes connected to "\
                        "Postgres and those discovered through AWS EC2.\n"\
                        "Postgres: \n#{pg_nodes.join("\n")}\n"\
                        "AWS: \n#{a_nodes.join("\n")}"),
       'pending'       => error_if(instances.pending),
       'running'       => valid_if(instances.running),
       'shutting_down' => error_if(instances.shutting_down),
       'terminated'    => error_if(instances.terminated),
       'stopping'      => error_if(instances.stopping),
       'stopped'       => error_if(instances.stopped),
      }.delete_if { |k, v| v.empty? }
    rescue => e
      error(e.message)
    end
  end

  def self.valid_if arr
    return arr.join("\n") unless arr.empty?

    error('---')
  end

  def self.error_if arr
    return arr if arr.empty?

    error(arr.join("\n"))
  end
end
end
