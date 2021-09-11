require 'aws-sdk-rds'

module Awry
  class Rds < Cli
    COLORS = {
      available: :green,
      'in-sync': :green,
    }

    no_commands do
      def client
        @_client ||= Aws::RDS::Client.new
      end
    end

    desc 'ls [PREFIX]', 'list clusters'
    def ls(prefix = nil)
      client.describe_db_clusters.map(&:db_clusters).flatten.map do |d|
        cluster = [ d.db_cluster_identifier, d.engine, color(d.status)]
        instances = d.db_cluster_members.map do |i|
          role = i.is_cluster_writer ? 'writer' : 'reader'
          [ '- ' + i.db_instance_identifier, role, color(i.db_cluster_parameter_group_status) ]
        end
        [ cluster ] + instances
      end.flatten(1).tap do |list|
        print_table list
      end
    end

    desc 'endpoints [CLUSTER]', 'list endpoints'
    def endpoints(cluster = nil)
      client.describe_db_cluster_endpoints(db_cluster_identifier: cluster).map(&:db_cluster_endpoints).flatten.map do |e|
        [ e.db_cluster_identifier, e.endpoint_type, color(e.status), e.endpoint ]
      end.tap do |list|
        print_table list
      end
    end

  end
end
