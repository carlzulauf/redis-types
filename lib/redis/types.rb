require 'securerandom'
require 'delegate'

require 'active_support/core_ext'
require 'active_support/concern'
require 'redis'
require 'redis/namespace'

require 'redis/types/marshal'
require 'redis/types/client_methods'

require 'redis/types/hash_map'
require 'redis/types/hash_map/track_changes'
require 'redis/types/hash_map/strategies/merge'
require 'redis/types/hash_map/strategies/merge_current_wins'
require 'redis/types/hash_map/strategies/lock'
require 'redis/types/hash_map/strategies/fail'

require 'redis/types/big_hash'

class Redis
  module Types
    class << self
      def load(key, options = {})
        redis = options[:redis] || Redis.current
        case redis.type( key )
        when "hash"
          if options[:type].to_s =~ /hash_map/ or redis.object(:encoding, key) == "zipmap"
            HashMap.new(key, :redis => redis)
          else
            BigHash.new(key, :redis => redis)
          end
        when "string"
          Marshal.load redis.get( key )
        end
      end
      alias_method :open, :load
      alias_method :find, :load
    end
  end
end
