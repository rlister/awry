# coding: utf-8
require 'aws-sdk-ec2'

module Awry
  class Vpc < Cli
    COLORS = {
      active: :green,
      available: :green,
      deleted: :red,
      expired: :red,
      failed: :red,
      rejected: :red,
    }

    no_commands do
      def client
        @_client ||= Aws::EC2::Client.new
      end
    end

    desc 'ls [PREFIX]', 'list vpcs'
    def ls(prefix = nil)
      client.describe_vpcs.map(&:vpcs).flatten.map do |v|
        [ tag_name(v, '-'), v.vpc_id, color(v.state), v.cidr_block ]
      end.tap do |list|
        list.select! { |l| l.first.start_with?(prefix) } if prefix
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'subnets [PREFIX]', 'list subnets'
    def subnets(prefix = nil)
      client.describe_subnets.map(&:subnets).flatten.map do |s|
        [ tag_name(s, '') , s.subnet_id, color(s.state), s.vpc_id, s.cidr_block, s.availability_zone, s.availability_zone_id ]
      end.tap do |list|
        list.select! { |l| l.first.start_with?(prefix) } if prefix
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'peers', 'list vpc peers'
    def peers
      client.describe_vpc_peering_connections.map(&:vpc_peering_connections).flatten.map do |p|
        [
          tag_name(p, '-'), p.vpc_peering_connection_id, color(p.status.code),
          p.requester_vpc_info.vpc_id, p.accepter_vpc_info.vpc_id,
          p.requester_vpc_info.cidr_block, p.accepter_vpc_info.cidr_block,
        ]
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'sg', 'list security groups'
    def sg
      client.describe_security_groups.map(&:security_groups).flatten.map do |s|
        [ s.group_name, s.group_id, s.vpc_id, '→'+s.ip_permissions.count.to_s, s.ip_permissions_egress.count.to_s+'→' ]
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'delete VPC', 'delete vpc'
    def delete(vpc_id)
      if yes?("Really delete vpc #{vpc_id}?", :yellow)
        p client.delete_vpc(vpc_id: vpc_id)
      end
    rescue Aws::EC2::Errors::DependencyViolation => e
      error(e.message)
    rescue Aws::EC2::Errors::InvalidVpcIDNotFound => e
      error(e.message)
    end

  end
end
