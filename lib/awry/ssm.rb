require 'aws-sdk-ssm'

module Awry
  class Ssm < Cli
    no_commands do
      def client
        @_client ||= Aws::SSM::Client.new
      end
    end

    desc 'ls [PREFIX]', 'list parameters'
    def ls(prefix = '/')
      filters = [ { key: :Name, option: :BeginsWith, values: [ prefix.sub(/^(\w)/, '/\1') ] } ]
      client.describe_parameters(parameter_filters: filters).each do |response|
        response.parameters.each { |p| puts p.name }
        sleep 0.1               # this api will throttle easily
      end
    end

    desc 'get NAME', 'get parameter value'
    method_option :decrypt, aliases: '-d', type: :boolean, default: false, desc: 'decrypt SecureString'
    def get(name)
      puts client.get_parameter(name: name, with_decryption: options[:decrypt]).parameter.value
    rescue Aws::SSM::Errors::ParameterNotFound => e
      error(e.message)
    end

    desc 'put NAME VALUE', 'put parameter'
    method_option :description, aliases: '-d', type: :string,  default: nil,     desc: 'description for params'
    method_option :key_id,      aliases: '-k', type: :string,  default: nil,     desc: 'KMS key for SecureString params'
    method_option :overwrite,   aliases: '-o', type: :boolean, default: false,   desc: 'overwrite existing params'
    method_option :type,        aliases: '-t', type: :string,  default: :String, desc: 'String, StringList, SecureString'
    def put(name, value)
      client.put_parameter(
        name:        name,
        value:       value,
        description: options[:description],
        type:        options[:type],
        key_id:      options[:key_id],
        overwrite:   options[:overwrite],
      )
    rescue Aws::SSM::Errors::ParameterAlreadyExists => e
      error(e.message)
    end

    desc 'delete NAME', 'delete parameter'
    def delete(name)
      if yes?("Really delete parameter #{name}?", :yellow)
        client.delete_parameter(name: name)
      end
    rescue Aws::SSM::Errors::ParameterNotFound => e
      error(e.message)
    end

  end
end
