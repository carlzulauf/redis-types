module Redis::Types
  class BigHash
    include ClientMethods
    include Enumerable

    attr_accessor :default, :default_proc

    def initialize(*args, &default_proc)
      options = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = options[:namespace] if options[:namespace].present?
      if block_given?
        self.default_proc = default_proc
      else
        self.default = options[:default] if options[:default].present?
      end
      self.merge!( options[:data] ) if options[:data].present?
    end

    def ==(other)
      return false unless other.respond_to? :namespace and other.respond_to? :key
      other.namespace == namespace and other.key == key
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

    def delete(col, &fail)
      value = self[col]
      redis.hdel key, col
      (value.nil? and block_given?) ? fail.call(col) : value
    end

    def delete_if(&block)
      each_pair do |key, value|
        yield(key, value) ? delete(key) : nil
      end
      self
    end

    def each
      if block_given?
        keys.each do |col|
          yield [ col, self[col] ]
        end
        self
      else
        to_a.each
      end
    end
    alias_method :each_pair, :each

    def each_key(&block)
      keys.each(&block)
    end

    def each_value(&block)
      each_pair do |key, value|
        yield value
      end
    end

    def empty?
      length == 0
    end

    def eql?(other)
      self == other or self.to_hash == other.to_hash
    end

    def keys
      redis.hkeys key
    end

    def length
      redis.hlen key
    end

    def merge!(other_hash)
      other_hash.each_pair do |key, value|
        self[key] = value
      end
    end

    def to_hash
      {}.tap do |hash|
        each_pair do |key, value|
          hash[key] = value
        end
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
