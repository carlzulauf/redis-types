module Redis::Types
  class BigHash
    include ClientMethods

    def initialize(*args)
      options = args.extract_options!
    end
  end
end
