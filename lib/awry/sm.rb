require 'aws-sdk-secretsmanager'

module Awry
  class Sm < Cli
    no_commands do
      def client
        @_client ||= Aws::SecretsManager::Client.new
      end
    end

    desc 'ls', 'list secrets'
    def ls(prefix = nil)
      client.list_secrets.map(&:secret_list).flatten.tap do |secrets|
        secrets.select! { |s| s.name.start_with?(prefix) } if prefix
      end.map do |s|
        [ s.name, s.description, s.created_date, s.primary_region ]
      end.tap do |list|
        print_table list.sort
      end
    end

    desc 'value SECRET', 'get secret value'
    method_option :show, aliases: '-s', type: :boolean, default: false, desc: 'show secret values'
    def value(secret_id)
      string = client.get_secret_value(secret_id: secret_id).secret_string
      hash = JSON.parse(string)
      hash.each { |k,v| hash[k] = "#{v.bytesize} bytes" } unless options[:show]
      print_table hash.sort
    end

  end
end
