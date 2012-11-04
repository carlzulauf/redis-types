require 'securerandom'
require 'delegate'

require 'active_support/core_ext'
require 'active_support/concern'
require 'redis'
require 'redis/namespace'

require 'redis/types/marshal'
require 'redis/types/client_methods'

require 'redis/types/hash'
require 'redis/types/hash/track_changes'
require 'redis/types/hash/strategies/merge'
require 'redis/types/hash/strategies/change'
require 'redis/types/hash/strategies/lock'

require 'redis/types/big_hash'

require 'redis/types/array'

require 'redis/types/list'

require 'redis/types/set'

class Redis
  module Types
    class << self
      
      def load(key, options = {})
        type  = options[:type].to_s
        case redis.type( key )
        when "hash"
          load_hash( key, type, options )
        when "string"
          Marshal.load redis.get( key )
        when "list"
          load_list( key, type, options )
        when "set"
          Set.new(key, options)
        end
      end
      
      alias_method :open, :load
      alias_method :find, :load
      
      def load_hash(key, type = "", options = {})
        if type =~ /big_hash/
          BigHash.new(key, options)
        elsif type =~ /hash/
          Hash.new(key, options)
        else
          if redis.object(:encoding, key) == "zipmap"
            Hash.new(key, options)
          else
            BigHash.new(key, options)
          end
        end
      end

      def load_list(key, type = "", options = {})
        if type =~ /list/
          List.new(key, options)
        elsif type =~ /array/
          Array.new(key, options)
        else
          if redis.object(:encoding, key) == "ziplist"
            Array.new(key, options)
          else
            List.new(key, options)
          end
        end
      end

      def redis(options = {})
        options[:redis] || Redis.current
      end

    end
  end
end
