module Redis::Types
  class HashMap < Delegator
    include ClientMethods
    attr_reader :current, :strategy

    def initialize(*args)
      options = args.extract_options!
      self.key        = args.shift || options[:key]
      self.redis      = options[:redis]     if options[:redis].present?
      self.namespace  = optinos[:namespace] if options[:namespace].present?
      @strategy = (options[:strategy] || :replace).to_s.camelize
      if strategy and Strategies.const_defined?(strategy)
        extend Strategies.const_get(strategy)
      end
      reload
      merge!(options[:data]) if options[:data].present?
    end

    def save
      redis.pipelined do |r|
        r.del key
        r.mapped_hmset(key, current) unless current.empty?
      end
    end

    def destroy
      redis.del key
    end

    def reload
      @current = __read__
    end

    def __getobj__
      current
    end

    def __read__
      HashWithIndifferentAccess.new( redis.hgetall key )
    end

    module Strategies
      # Attempts to merge concurrently made changes.
      # Gives priority to the changes made concurrently
      # when there is a conflict.
      module Merge
        def self.extend_object(obj)
          obj.extend TrackChanges
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
            (added + changed).each{|key| changes[key] = current[key] }
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

      # Attempts to merge concurrently made changes.
      # Gives priority to changes in the current hash
      # when there is a conflict.
      module MergeCurrentWins
        # TODO
      end

      # Raises an error when attempt is made to save a hash
      # that has been edited concurrently.
      module Fail
        # TODO
      end

      # Hash must be locked before it can be saved. Error is
      # raised when attempting to lock a hash that is already
      # locked.
      module Lock
        # TODO
      end
    end

    module TrackChanges
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

  end
end
