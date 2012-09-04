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
require 'redis/types/hash_map/strategies/change'
require 'redis/types/hash_map/strategies/lock'

require 'redis/types/big_hash'

class Redis
  module Types
    class << self
      def load(key, options = {})
        redis = options[:redis] || Redis.current
        type  = options.delete(:type).to_s
        case redis.type( key )
        when "hash"
          if type =~ /big_hash/
            BigHash.new(key, options)
          elsif type =~ /hash_map/
            HashMap.new(key, options)
          else
            if redis.object(:encoding, key) == "zipmap"
              HashMap.new(key, options)
            else
              BigHash.new(key, options)
            end
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
