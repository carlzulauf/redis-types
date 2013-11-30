# Attempts to merge concurrently made changes.
# Gives priority to the changes made concurrently
# when there is a conflict.
module Redis::Types::Hash::Strategies::Merge
  extend ActiveSupport::Concern

  included do
    include Redis::Types::Hash::TrackChanges
  end

  def self.extend_object(obj)
    obj.extend Redis::Types::Hash::TrackChanges
    super
  end

  def version
    @version ||= self.class.generate_key
  end

  def save(max_attempts = 5)
    saved, attempts = false, 0
    until saved or attempts >= max_attempts
      attempts += 1
      redis.watch key
      last_saved = redis.hget key, "__version__"
      if last_saved.nil? or version == last_saved
        saved = redis.multi do |r|
          r.hdel key, *deleted unless deleted.empty?
          r.mapped_hmset key, current_changes
        end
      else
        reload
      end
    end
    @original = current.dup
  end

  def current_changes
    {}.tap do |changes|
      (added + changed).each{|key| changes[key] = Redis::Types::Marshal.dump(current[key]) }
      changes[:__version__] = self.class.generate_key
    end
  end

  def reload # merging reload
    update = __read__
    @version = update.delete(:__version__)
    if @original.nil?
      @current = update.dup
    else
      changes = update.dup
      changes.delete_if {|key, value| @original[key] == value }
      @current.merge!(changes)
      @current.delete_if {|k,v| @original.key?(k) and !update.key?(k) }
    end
    @original = update
  end
end
