module Redis::Types
  class Set < Delegator
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
      self.current = ::Set.new redis.smembers(key).map{|v| Marshal.load v }
    end

    def save
      destroy
      redis.sadd key, current.to_a
    end

    def destroy
      redis.del key
    end
  end
end
