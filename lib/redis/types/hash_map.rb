module Redis::Types
  class HashMap < Delegator
    include ClientMethods
    attr_reader :current, :strategy

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = options[:namespace] if options[:namespace].present?
      @strategy = (options[:strategy] || :replace).to_s.camelize
      if strategy and Strategies.const_defined?(strategy)
        extend Strategies.const_get(strategy)
      end
      reload
      merge!(options[:data]) if options[:data].present?
    end

    def save
      data = {}
      current.each_pair do |k,v|
        data[k] = Redis::Types::Marshal.dump(v)
      end
      redis.pipelined do |r|
        r.del key
        r.mapped_hmset(key, data) unless data.empty?
      end
    end

    def destroy
      redis.del key
    end

    def reload
      @current = __read__
    end

    def __getobj__
      current
    end

    def __read__
      HashWithIndifferentAccess.new.tap do |hash|
        redis.hgetall(key).each_pair do |k,v|
          hash[k] = Redis::Types::Marshal.load(v)
        end
      end
    end

    module Strategies
      # Namespace for HashMap strategies
    end

  end
end
