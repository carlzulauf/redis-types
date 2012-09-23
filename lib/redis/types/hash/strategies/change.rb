# Attempts to merge concurrently made changes.
# Gives priority to the changes made concurrently
# when there is a conflict.
module Redis::Types::Hash::Strategies::Change
  def self.extend_object(obj)
    obj.extend Redis::Types::Hash::TrackChanges
    super
  end

  def save
    redis.pipelined do |r|
      d = deleted
      r.hdel key, *d unless d.empty?
      r.mapped_hmset key, current_changes
    end
    @current, @original = nil, nil
    reload
  end

  def current_changes
    {}.tap do |changes|
      (added + changed).each{|key| changes[key] = Redis::Types::Marshal.dump(current[key]) }
    end
  end

  def reload # merging reload where current wins
    update = __read__
    if @original.nil?
      @current = update.dup
    else
      changes = current_changes
      deleted = self.deleted
      @current = update.merge(changes)
      @current.delete_if{|k,v| deleted.member?(k) }
    end
    @original = update
  end
end
