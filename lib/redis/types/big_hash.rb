module Redis::Types
  class BigHash
    include ClientMethods
    include Enumerable

    attr_accessor :default, :default_proc

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
      value = Marshal.load( redis.hget key, col )
      if value.nil?
        default_proc ? default_proc.call(self,col) : default
      else
        value
      end
    end

    def []=(col, value)
      redis.hset key, col, Marshal.dump(value)
    end

    def assoc(key)
      value = self[key]
      value.nil? ? nil : [key, value]
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
    alias_method :clear, :destroy

  end
end
