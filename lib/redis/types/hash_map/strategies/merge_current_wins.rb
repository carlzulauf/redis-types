# Attempts to merge concurrently made changes.
# Gives priority to the changes made concurrently
# when there is a conflict.
module Redis::Types::HashMap::Strategies::MergeCurrentWins
  def self.extend_object(obj)
    obj.extend Redis::Types::HashMap::TrackChanges
    obj.extend Redis::Types::HashMap::Strategies::Merge
    super
  end

  def reload # merging reload where current wins
    update = __read__
    @version = update.delete(:__version__)
    if @original.nil?
      @current = update.dup
    else
      changes = @current.dup
      changes.delete_if {|key, value| @original[key] == value }
      changes = update.merge(changes)
      changes.delete_if {|k,v| @original.key?(k) and !@current.key?(k) }
      @current = changes
    end
    @original = update
  end
end
