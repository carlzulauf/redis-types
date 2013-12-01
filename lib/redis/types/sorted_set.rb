module Redis::Types
  class SortedSet
    include ClientMethods

    def initialize(*args)
      options         = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = options[:namespace] if options[:namespace].present?
    end

    def add(value, score = 0)
      redis.zadd key, score, value
    end

    def first(count = 1)
      results = redis.zrange key, 0, (count - 1)
      count == 1 ? results.first : results
    end

    def length
      redis.zcard key
    end

    def delete(value)
      redis.zrem key, value
    end

    def destroy
      redis.del key
    end

  end
end
