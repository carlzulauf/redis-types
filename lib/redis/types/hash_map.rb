module Redis::Types
  class HashMap < Delegator
    include ClientMethods
    attr_reader :current, :original

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = optinos[:namespace] if options[:namespace].present?
      reload
      merge!(options[:data]) if options[:data].present?
    end

    def save
      redis.pipelined do |r|
        r.del key
        r.mapped_hmset(key, current) unless current.empty?
      end
    end

    def destroy
      redis.del key
    end

    def load
      @original = HashWithIndifferentAccess.new( redis.hgetall key )
    end

    def reload
      load
      @current = original.dup
    end

    def __getobj__
      current
    end
  end
end
