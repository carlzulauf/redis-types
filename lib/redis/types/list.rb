module Redis::Types
  class List
    include ClientMethods
    include Enumerable

    delegate :&, :*, :+, :-, :|, :abbrev, :assoc, :combination, :compact,
             :flatten, :hash, :index, :join, :pack, :permutation, :product,
             :rassoc, :repeated_combination, :repeated_permutation, :reverse,
             :rindex, :rotate, :shelljoin, :shuffle, :to_csv, :transpose, :uniq,
             :zip, :to => :to_a

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
      push *other_array
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

    def fetch(index, default = nil)
      if length > index
        self[index]
      else
        if block_given?
          yield
        elsif default
          default
        else
          raise IndexError
        end
      end
    end

    def last
      self[-1]
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
    alias_method :size, :length

    def pop
      Marshal.load( redis.rpop key )
    end

    def push(*values)
      redis.rpush key, marshal( values )
    end

    def sample(n = nil)
      l = length
      if n
        n = l if n > l
        indexes = []
        while indexes.length < n
          r = rand(l)
          indexes << r unless indexes.member?(r)
        end
        unmarshal redis.pipelined{|r| indexes.each{|i| r.lindex(key, i) } }
      else
        self[ rand(l) ]
      end
    end

    def shift(n = nil)
      if n
        unmarshal redis.pipelined{|r| n.times{ r.lpop key } }
      else
        Marshal.load(redis.lpop key)
      end
    end

    def unshift(*values)
      redis.lpush key, marshal( values.reverse )
    end

    def values_at(*args)
      values = []
      args.each do |i|
        if i.kind_of?(Range)
          values += self[i]
        else
          values << self[i]
        end
      end
      values
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
