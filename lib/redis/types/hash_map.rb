module Redis::Types
  class HashMap < SimpleDelegator
    include ClientMethods
    attr_reader :current, :original

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.unshift || options[:key] || self.class.generate_key
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = optinos[:namespace] if options[:namespace].present?
      reload!
      __setobj__ current
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

    private

    def load!
      @original = HashWithIndifferentAccess.new( redis.hgetall key )
    end

    def reload!
      load!
      @current = @original.dup
    end
  end
end
