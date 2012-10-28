module Redis::Types
  class List
    include ClientMethods
    include Enumerable

    delegate :&, :*, :+, :-, :abbrev, :assoc, :combination, :compact, :to => :to_a

    def initialize(*args)
      options         = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = options[:namespace] if options[:namespace].present?
    end

    def <<(value)
      redis.rpush key, Marshal.dump( value )
      self
    end
    alias_method :push, :<<

    def <=>(other)
      case other
      when Redis::Types::List
        key <=> other.key
      when ::Array
        to_a <=> other
      end
    end

    def ==(other)
      return false unless other.respond_to? :namespace and other.respond_to? :key
      other.namespace == namespace and other.key == key
    end
    alias_method :eql?, :==

    def [](index, length = nil)
      if length
        return nil if length < 0
        return [] if length == 0
        unmarshal redis.lrange( key, index, index + length - 1 )
      else
        if index.kind_of?(Range)
          range(index)
        else
          Marshal.load( redis.lindex( key, index ) )
        end
      end
    end
    alias_method :slice, :[]

    def at(index)
      self[index]
    end

    def clear
      destroy
      self
    end

    def concat(other_array)
      redis.rpush key, other_array.map{|v| Marshal.dump v }
    end

    def count
      if block_given?
        super
      else
        length
      end
    end

    def delete(value)
      redis.lrem(key, 0, value) == 0 ? nil : value
    end

    def range(start, stop = nil)
      if start.kind_of?(Range)
        range(start.first, start.last)
      else
        unmarshal redis.lrange( key, start, stop )
      end
    end

    def each
      if block_given?
        i, c = 0, length
        while i < c
          yield Marshal.load( redis.lindex( key, i ) )
          i += 1
        end
        self
      else
        to_a.each
      end
    end

    def empty?
      length == 0
    end

    def length
      redis.llen key
    end

    def pop
      Marshal.load( redis.rpop key )
    end

    def destroy
      redis.del( key )
    end

    # Here for compatability with Redis::Types::Array only. Does nothing.
    def save; true; end

    def to_a
      range(0, -1)
    end

  private
    def unmarshal(a)
      a.map{|v| Marshal.load v }
    end
    def marshal(a)
      a.map{|v| Marshal.dump v }
    end
  end
end
