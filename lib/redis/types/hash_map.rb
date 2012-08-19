module Redis::Types
  class HashMap < SimpleDelegator
    include ClientMethods
    attr_accessor :key
    def initialize(*args)
      options = args.extract_options!
      self.key    = args.unshift || options[:key] || SecureRandom.hex
      self.redis  = options[:redis] if options[:redis].present?
      @original   = load
      @current    = @original.dup
      __setobj__ @current
    end

    private

    def load
      HashWithIndifferentAccess.new( redis.hgetall key )
    end
  end
end
