require 'aws-sdk-s3'

module Awry
  class S3 < Cli
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
        @_client ||= Aws::S3::Client.new
      end

      def wait_until_empty(bucket)
        while true
          break if client.list_objects_v2(bucket: bucket, max_keys: 1).key_count == 0
          puts 'waiting for objects to delete'
          sleep 3
        end
      end
    end

    desc 'ls [PREFIX]', 'list buckets'
    def ls(prefix = nil)
      if prefix&.include?('/')
        p client
      else
        buckets(prefix)
      end
    end

    desc 'buckets [PREFIX]', 'list buckets'
    def buckets(prefix = nil)
      client.list_buckets.buckets.tap do |buckets|
        buckets.select! { |b| b.name.start_with?(prefix) } if prefix
      end.map do |b|
        region = client.get_bucket_location(bucket: b.name).location_constraint
        [ b.name, region, b.creation_date ]
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'empty BUCKET', 'delete objects from bucket'
    def empty(bucket)
      if yes?("Really delete objects and versions from bucket #{bucket}?", :yellow)
        Aws::S3::Resource.new.bucket(bucket).object_versions.batch_delete!
      end
    end

    desc 'delete BUCKET', 'delete bucket'
    method_option :empty, aliases: '-e', type: :boolean, default: false, desc: 'delete all objects'
    def delete(bucket)
      if options[:empty]
        empty(bucket)
        wait_until_empty(bucket)
      end
      if yes?("Really delete bucket #{bucket}?", :yellow)
        client.delete_bucket(bucket: bucket)
      end
    rescue Aws::S3::Errors::BucketNotEmpty => e
      error(e.message)
    end

    desc 'policy BUCKET', 'get bucket policy'
    def policy(bucket)
      client.get_bucket_policy(bucket: bucket).policy.tap do |policy|
        puts JSON.pretty_generate(JSON.parse(policy.gets))
      end
    end

    desc 'acl BUCKET', 'get bucket acl'
    def acl(bucket)
      client.get_bucket_acl(bucket: bucket).grants.map do |g|
        [ g.grantee.display_name, g.grantee.id, g.grantee.type, g.permission ]
      end.tap do |list|
        print_table list
      end
    end

  end
end
