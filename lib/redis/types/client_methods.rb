module Redis::Types::ClientMethods
  extend ActiveSupport::Concern

  included do
    attr_writer :key
  end

  def key
    @key ||= self.class.generate_key
  end

  def namespace
    redis.respond_to? :namespace ? redis.namespace : nil
  end
  
  def namespace=(ns)
    if ns.present?
      redis = Redis::Namespace.new(ns, redis)
    else
      redis = redis.redis if redis.kind_of?(Redis::Namespace)
    end
  end

  def redis
    @redis ||= self.class.redis
  end
  
  def redis=(connection)
    @redis = connection
  end

  module ClassMethods
  
    def redis
      unless self.class_variable_defined?(:'@@redis')
        self.class_variable_set(:'@@redis', ::Redis.current)
      end
      self.class_variable_get(:'@@redis')
    end
  
    def redis=(connection)
      self.class_variable_set(:'@@redis', connection)
    end
  
    def generate_key
      t = Time.now
      t.strftime('%Y%m%d%H%M%S.') + t.usec.to_s.rjust(6,'0') + '.' + SecureRandom.hex(8)
    end
  
  end
end
