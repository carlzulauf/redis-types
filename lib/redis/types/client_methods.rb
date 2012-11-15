module Redis::Types::ClientMethods
  extend ActiveSupport::Concern

  included do
    class_eval(<<-EOS, __FILE__, __LINE__ + 1)
      @@redis = nil unless defined?(@@redis)

      def self.redis
        @@redis ||= Redis.current
      end

      def self.redis=(connection)
        @@redis = connection
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
  
    def redis
      self.class_eval("@@redis ||= Redis.current")
    end
  
    def generate_key
      t = Time.now
      t.strftime('%Y%m%d%H%M%S.') + t.usec.to_s.rjust(6,'0') + '.' + SecureRandom.hex(8)
    end
  
  end
end
