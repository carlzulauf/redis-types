module Redis::Types
  class List
    include ClientMethods
    include Enumerable

    def initialize(*args)
      options         = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = options[:namespace] if options[:namespace].present?
    end

    def <<(value)
      redis.rpush key, value
    end

    def each
      if block_given?
        i, c = 0, length
        while i < c
          yield redis.lindex( i )
        end
        self
      else
        to_a.each
      end
    end

    def length
      redis.llen key
    end

    def pop
      redis.rpop key
    end

    # Here for compatability with Redis::Types::Array only. Does nothing.
    def save; true; end

    def to_a
      redis.lrange 0, -1
    end
  end
end
