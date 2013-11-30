module Redis::Types::ClientMethods
  extend ActiveSupport::Concern

  included do |klass|
    class_eval(<<-EOS, __FILE__, __LINE__ + 1)
      def self.base_type
        "#{klass.to_s}".constantize
      end
    EOS

    attr_writer :key
  end

  def key
    @key ||= self.class.generate_key
  end

  def namespace
    redis.respond_to?(:namespace) ? redis.namespace : nil
  end

  def namespace=(ns)
    if ns.present?
      redis = self.redis.kind_of?(Redis::Namespace) ? self.redis.redis : self.redis
      self.redis = Redis::Namespace.new(ns, :redis => redis)
    else
      self.redis = self.redis.redis if self.redis.kind_of?(Redis::Namespace)
    end
  end

  def redis
    @redis ||= self.class.redis
  end

  def redis=(connection)
    @redis = connection
  end

  module ClassMethods

    def namespace(ns = nil)
      if ns.present?
        @_namespace = ns
        conn = redis.respond_to?(:redis) ? redis.redis : redis
        @_redis = Redis::Namespace.new(ns, redis: conn)
      end
      @_namespace
    end

    def redis
      @_redis || Redis.current
    end

    def redis=(conn)
      @_redis = conn
    end

    def generate_key
      t = Time.now
      t.strftime('%Y%m%d%H%M%S.') + t.usec.to_s.rjust(6,'0') + '.' + SecureRandom.hex(8)
    end

    def strategy(name = nil)
      if name
        @_strategy = name
        include base_type.const_get(:Strategies).const_get(name.to_s.camelize)
      end
      @_strategy
    end

    def fixed_attrs(*attrs)
      attrs.each do |a|
        define_method(a) do
          self[a]
        end

        define_method("#{a}=") do |value|
          self[a] = value
        end
      end
    end

  end
end
