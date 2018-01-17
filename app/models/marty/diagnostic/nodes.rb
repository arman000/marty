module Marty::Diagnostic; class Nodes < Base
  def self.generate
    pack do
      begin
        a_nodes = Aws::Ec2Instance.new.nodes.sort if
          Aws::Ec2Instance.is_aws?
      rescue => e
        a_nodes = [e.message]
      end
      pg_nodes = Node.get_nodes.sort
      a_nodes.nil? || pg_nodes == a_nodes ? pg_nodes.join("\n") :
        error("There is a discrepancy between nodes connected to "\
              "Postgres and those discovered through AWS EC2.\n"\
              "Postgres: \n#{pg_nodes.join("\n")}\n"\
              "AWS: \n#{a_nodes.join("\n")}")
    end
  end
end
end
