module Redis::Types::HashMap::TrackChanges
  def original; @original; end

  def changes
    HashWithIndifferentAccess.new.tap do |changes|
      current.each_pair do |key, value|
        changes[key] = [ original[key], current[key] ] unless original[key] == current[key]
      end
      (original.keys - current.keys).each do |key|
        changes[key] = [ original[key], nil ]
      end
    end
  end

  def added
    current.keys - original.keys
  end

  def deleted
    original.keys - current.keys
  end

  def changed
    original.keys.select {|key| current.key?(key) and original[key] != current[key] }
  end
end
