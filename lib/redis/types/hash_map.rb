module Redis::Types
  class HashMap < SimpleDelegator
    include ClientMethods

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.unshift || options[:key] || self.class.generate_key
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = optinos[:namespace] if options[:namespace].present?
      @original = load
      @current  = @original.dup
      __setobj__ @current
    end

    def save
      redis.hmset key, *@current.to_a.flatten
    end

    def destroy
      redis.del key
    end

    private

    def load
      HashWithIndifferentAccess.new( redis.hgetall key )
    end
  end
end
