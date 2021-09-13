# coding: utf-8
require 'aws-sdk-ec2'

module Awry
  class Ec2 < Cli
    COLORS = {
      running: :green,
      terminated: :red,
    }

    no_commands do
      def client
        @_client ||= Aws::EC2::Client.new
      end
    end

    desc 'ls', 'list instances'
    def ls
      client.describe_instances.map(&:reservations).flatten.map(&:instances).flatten.map do |i|
        [ tag_name(i), i.instance_id, color(i.state.name), i.instance_type, i.placement.availability_zone, i.private_ip_address, i.public_ip_address, i.launch_time ]
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'terminate IDS', 'terminate instances'
    def terminate(*ids)
      return unless yes?("Really terminate instances: #{ids.join(',')}?", :yellow)
      client.terminate_instances(instance_ids: ids, dry_run: false).terminating_instances.map do |i|
        [ i.instance_id, color(i.previous_state.name), '→', color(i.current_state.name) ]
      end.tap do |list|
        print_table list
      end
    end
  end
end
