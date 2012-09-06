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

    def ==(other_hash)
      other_hash.key == key
    end

    def <=>(other_hash)
      key <=> other_hash.key
    end

    def [](col)
      Marshal.load( redis.hget key, col )
    end

    def []=(col, value)
      redis.hset key, col, Marshal.dump(value)
    end

    def each
      redis.hkeys( key ).each do |col|
        yield [ col, self[col] ]
      end
    end

    # for compatibility with HashMap only. doesn't to ANYTHING.
    def save; true; end

    def destroy
      redis.del key
    end
  end
end
