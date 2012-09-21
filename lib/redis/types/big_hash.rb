module Redis::Types
  class BigHash
    include ClientMethods
    include Enumerable

    attr_accessor :default, :default_proc

    delegate :hash, :invert, :merge, :to => :to_hash

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

    def fetch(*args)
      raise ArgumentError unless [1,2].include? args.length
      field = args.first
      if (value = self[field])
        value
      elsif block_given?
        yield
      elsif args.length == 2
        args[1]
      else
        raise KeyError, %{field "#{field}" not found}
      end
    end

    def flatten
      [].tap do |flat|
        each_pair do |field, value|
          flat << field
          flat << value
        end
      end
    end

    def has_key?(field)
      redis.hexists key, field
    end
    alias_method :include?, :has_key?
    alias_method :key?,     :has_key?
    alias_method :member?,  :has_key?

    def has_value?(value)
      values.any?{|v| v == value }
    end
    alias_method :value?, :has_value?

    # ClientMethods already defines #key as the redis key.
    # may need to re-examine this as HashMap#key doesn't work this way
    alias_method :__key__, :key
    def key(*args)
      case args.length
      when 0
        __key__
      when 1
        fetch(args.first, nil)
      else
        raise ArgumentError
      end
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
      self
    end

    def rassoc(value)
      each do |field, val|
        return [field, val] if val == value
      end
      nil
    end

    def reject(&block)
      to_hash.delete_if(&block)
    end

    def to_hash
      HashWithIndifferentAccess.new.tap do |hash|
        each_pair do |key, value|
          hash[key] = value
        end
      end
    end

    def values
      redis.hvals(key).map{|val|  Marshal.load(val) }
    end

    # for compatibility with HashMap only. doesn't to ANYTHING.
    def save; true; end

    def destroy
      redis.del key
    end
    alias_method :clear, :destroy

  end
end
