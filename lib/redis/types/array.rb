module Redis::Types
  class Array < Delegator
    include ClientMethods

    attr_accessor :current

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = options[:namespace] if options[:namespace].present?
      reload
    end

    def __getobj__
      current
    end

    def reload
      self.current = redis.lrange(key, 0, -1).map{|v| Marshal.load v }
    end

    def save
      redis.del   key
      redis.rpush key, current.map{|v| Marshal.dump v }
    end
  end
end
