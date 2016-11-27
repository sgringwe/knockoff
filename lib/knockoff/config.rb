module Knockoff
  class Config
    # The current environment. Normally set to Rails.env, but
    # will default to 'development' outside of Rails apps.
    attr_accessor :environment

    # An array of URIs to use for the replica pool.
    # TODO: Add support for inheriting from database.yml
    attr_accessor :replica_uris

    def initialize
      @environment = 'development'
      set_replica_uris
    end

    def replica_env_keys
      if ENV['KNOCKOFF_REPLICA_ENVS'].nil?
        []
      else
        ENV['KNOCKOFF_REPLICA_ENVS'].split(',').map(&:strip)
      end
    end

    private

    def set_replica_uris
      @replica_uris ||= parse_knockoff_replica_envs_to_uris
    end

    def parse_knockoff_replica_envs_to_uris
      # As a basic prevention of crashes, attempt to parse each DB uri
      # and don't add the uri to the final list if it can't be parsed
      replica_env_keys.map do |env_key|
        begin
          URI.parse(ENV[env_key])
        rescue URI::InvalidURIError
          Rails.logger.info "LOG NOTIFIER: Invalid URL specified in follower_env_keys. Not including URI, which may result in no followers used." # URI is purposely not printed to logs
          # Return a 'nil' which will be removed from
          # configs with `compact`, resulting in no configs and no followers,
          # therefore disabled since this env will not be in environments list.
          nil
        end
      end.compact
    end
  end
end
