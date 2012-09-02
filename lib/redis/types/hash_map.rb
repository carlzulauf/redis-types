module Redis::Types
  class HashMap < Delegator
    include ClientMethods
    attr_reader :current, :strategy

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = optinos[:namespace] if options[:namespace].present?
      @strategy = (options[:strategy] || :replace).to_s.camelize
      if strategy and Strategies.const_defined?(strategy)
        extend Strategies.const_get(strategy)
      end
      reload
      merge!(options[:data]) if options[:data].present?
    end

    def save
      redis.pipelined do |r|
        r.del key
        r.mapped_hmset(key, current) unless current.empty?
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
      HashWithIndifferentAccess.new( redis.hgetall key )
    end

    module Strategies
      # Namespace for HashMap strategies
    end

  end
end
