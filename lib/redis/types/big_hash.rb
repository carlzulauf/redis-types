module Redis::Types
  class BigHash
    include ClientMethods

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
  end
end
