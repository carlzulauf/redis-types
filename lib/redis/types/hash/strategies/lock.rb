# Hash must be locked before it can be saved. Error is
# raised when attempting to lock a hash that is already
# locked.
module Redis::Types::Hash::Strategies::Lock
  LOCK_TIMEOUT_SECONDS = 5 * 60
  
  def self.extend_object(obj)
    attr_writer :lock_timeout
    super
  end

  def lock_timeout
    @lock_timeout ||= LOCK_TIMEOUT_SECONDS
  end

  def lock
    reload true
  end

  def unlock
    redis.hdel(key, "__lock__") if locked?
    @locked = false
  end

  def locked?
    !! @locked
  end

  def []=(key, value)
    raise(Error, "Changes not permitted until lock has been aquired") unless locked?
    current[key] = value
  end

  def save
    raise(Error, "Hash must be locked before being saved") unless locked?
    data = {}
    current.each_pair do |k,v|
      data[k] = Redis::Types::Marshal.dump(v)
    end
    redis.pipelined do |r|
      r.del key
      r.mapped_hmset(key, data) unless data.empty?
    end
    @locked = false
  end

  def reload(perform_lock = false)
    if perform_lock
      __lock__
    else
      @current = __read__
      @current.delete(:__lock__)
    end
  end

  def __lock__(attempt = 1)
    t = Time.now
    redis.watch key
    data = redis.multi do
      redis.hgetall key
      redis.hset key, "__lock__", t.to_i
    end
    if data
      @current = HashWithIndifferentAccess.new( data.first )
      lock = @current.delete(:__lock__)
      lock = lock.nil? ? nil : Time.at(lock.to_i)
      if lock and (t - lock) < lock_timeout
        raise Error, "Specified hash is already locked"
      end
    else
      raise(Error, "Exceeded max tries to establish lock") if attempt > 4
      __lock__(attempt + 1)
    end
    @locked = true
  end

  class Error < StandardError
  end
end
