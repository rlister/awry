require 'aws-sdk-cloudformation'

module Awry
  class Cfn < Cli
    COLORS = {
      CREATE_COMPLETE: :green,
      CREATE_FAILED: :red,
      CREATE_IN_PROGRESS: :yellow,
      DELETE_COMPLETE: :green,
      DELETE_FAILED: :red,
      DELETE_IN_PROGRESS: :yellow,
      DELETE_SKIPPED: :yellow,
      DELETED: :red,
      ROLLBACK_COMPLETE: :red,
      ROLLBACK_IN_PROGRESS: :red,
      UPDATE_COMPLETE: :green,
      UPDATE_COMPLETE_CLEANUP_IN_PROGRESS: :yellow,
      UPDATE_FAILED: :red,
      UPDATE_IN_PROGRESS: :yellow,
    }

    ## stack statuses that are not DELETE_COMPLETE
    STATUSES = %i[
      CREATE_IN_PROGRESS CREATE_FAILED CREATE_COMPLETE
      DELETE_IN_PROGRESS DELETE_FAILED
      REVIEW_IN_PROGRESS
      ROLLBACK_IN_PROGRESS ROLLBACK_FAILED ROLLBACK_COMPLETE
      UPDATE_IN_PROGRESS UPDATE_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_COMPLETE
      UPDATE_ROLLBACK_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_ROLLBACK_COMPLETE
    ]

    no_commands do
      def client
        @_client ||= Aws::CloudFormation::Client.new
      end
    end

    desc 'ls [PREFIX]', 'list stacks'
    def ls(prefix = nil)
      client.list_stacks(stack_status_filter: STATUSES).map(&:stack_summaries).flatten.tap do |stacks|
        stacks.select! { |s| s.stack_name.start_with?(prefix) } if prefix
      end.map do |s|
        [s.stack_name, s.creation_time, color(s.stack_status), s.template_description]
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'parameters NAME', 'list stack parameters'
    def parameters(name)
      client.describe_stacks(stack_name: name).stacks.first.parameters.each_with_object({}) do |p, h|
        h[p.parameter_key] = p.parameter_value
      end.tap do |hash|
        print_table hash.sort
      end
    end

    desc 'outputs NAME', 'list stack outputs'
    def outputs(name)
      client.describe_stacks(stack_name: name).stacks.first.outputs.each_with_object({}) do |o, hash|
        hash[o.output_key] = o.output_value
      end.tap do |hash|
        print_table hash.sort
      end
    end

    desc 'resources NAME', 'list stack reasources'
    method_option :match, aliases: '-m', type: :string,  default: nil, desc: 'regex filter type of resource'
    def resources(name)
      client.list_stack_resources(stack_name: name).map(&:stack_resource_summaries).flatten.tap do |resources|
        if options[:match]
          regexp = Regexp.new(options[:match], Regexp::IGNORECASE)
          resources.select! { |r| regexp.match(r.resource_type) }
        end
      end.map do |r|
        [ r.logical_resource_id, r.resource_type, color(r.resource_status), r.physical_resource_id ]
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'delete NAME', 'deletes stack'
    def delete(name)
      if yes?("Really delete stack #{name}?", :yellow)
        client.delete_stack(stack_name: name)
      end
    end

    desc 'events NAME', 'show events for stack'
    method_option :number, aliases: '-n', type: :numeric, default: nil, desc: 'return n most recent events'
    def events(name)
      events = client.describe_stack_events(stack_name: name).map(&:stack_events).flatten
      events = events.first(options[:number]) if options[:number]
      events.map do |e|
        [ e.timestamp, color(e.resource_status), e.resource_type, e.logical_resource_id, e.resource_status_reason ]
      end.tap do |list|
        print_table list.reverse
      end
    end

    desc 'limits', 'describe cloudformation account limits'
    def limits
      client.describe_account_limits.account_limits.map do |l|
        [l.name, l.value]
      end.tap do |list|
        print_table list.sort
      end
    end

  end
end
