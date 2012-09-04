module Redis::Types
  class BigHash
    include ClientMethods
    include Enumerable

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = options[:namespace] if options[:namespace].present?
    end

    def [](col)
      Marshal.load( redis.hget key, col )
    end

    def []=(col, value)
      redis.hset key, col, Marshal.dump(value)
    end

    def each
      @i    ||= 0
      @keys ||= redis.hkeys( key )
      col = @keys[@i]
      yield [ col, self[col] ]
      @i += 1
    end

    def rewind
      @i, @keys = nil, nil
    end
  end
end
