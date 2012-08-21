require 'securerandom'
require 'delegate'

require 'active_support/core_ext'
require 'active_support/concern'
require 'redis'
require 'redis/namespace'

require 'redis/types/marshal'
require 'redis/types/client_methods'
require 'redis/types/hash_map'
require 'redis/types/big_hash'

class Redis
  module Types
    class << self
      def load(key, options = {})
        redis = options[:redis] || Redis.current
        case redis.type( key )
        when "hash"
          if options[:type] =~ /hash_map/ or redis.object(:encoding, key) == "zipmap"
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
