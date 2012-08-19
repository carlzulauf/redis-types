module Redis::Types::ClientMethods
  def self.included(base)
    base.send(:extend,  ClassMethods)
    base.send(:include, InstanceMethods)
  end
  module InstanceMethods
    def redis
      @redis ||= self.class.redis
    end
    def redis=(connection)
      @redis = connection
    end
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
  end
end
